#!/usr/bin/env python3
"""
evdi-daemon — conecta um display virtual via libevdi para GNOME/Wayland.
Fica em execução enquanto o monitor virtual deve existir.
"""
import ctypes, os, select, signal, sys

LIBEVDI      = '/usr/lib/libevdi.so.1'
EVDI_AVAILABLE = 1
BUF_ID         = 1
MAX_RECTS      = 16

try:
    lib = ctypes.CDLL(LIBEVDI)
except OSError as e:
    sys.exit(f"ERRO: não foi possível carregar {LIBEVDI}: {e}")

# ---------- structs ----------
class Mode(ctypes.Structure):
    _fields_ = [
        ('width',          ctypes.c_int),
        ('height',         ctypes.c_int),
        ('refresh_rate',   ctypes.c_int),
        ('bits_per_pixel', ctypes.c_int),
        ('pixel_format',   ctypes.c_uint32),
    ]

class Rect(ctypes.Structure):
    _fields_ = [
        ('x1', ctypes.c_int), ('y1', ctypes.c_int),
        ('x2', ctypes.c_int), ('y2', ctypes.c_int),
    ]

class Buffer(ctypes.Structure):
    _fields_ = [
        ('id',         ctypes.c_int),
        ('buffer',     ctypes.c_void_p),
        ('width',      ctypes.c_int),
        ('height',     ctypes.c_int),
        ('stride',     ctypes.c_int),
        ('rects',      ctypes.POINTER(Rect)),
        ('rect_count', ctypes.c_int),
    ]

DpmsHandlerType  = ctypes.CFUNCTYPE(None, ctypes.c_int, ctypes.c_void_p)
ModeChangedType  = ctypes.CFUNCTYPE(None, Mode, ctypes.c_void_p)
UpdateReadyType  = ctypes.CFUNCTYPE(None, ctypes.c_int, ctypes.c_void_p)
CrtcStateType    = ctypes.CFUNCTYPE(None, ctypes.c_int, ctypes.c_void_p)

class EventCtx(ctypes.Structure):
    _fields_ = [
        ('dpms_handler',         DpmsHandlerType),
        ('mode_changed_handler', ModeChangedType),
        ('update_ready_handler', UpdateReadyType),
        ('crtc_state_handler',   CrtcStateType),
        ('cursor_set_handler',   ctypes.c_void_p),
        ('cursor_move_handler',  ctypes.c_void_p),
        ('ddcci_data_handler',   ctypes.c_void_p),
        ('user_data',            ctypes.c_void_p),
    ]

# ---------- assinaturas ----------
lib.evdi_check_device.restype     = ctypes.c_int
lib.evdi_check_device.argtypes    = [ctypes.c_int]
lib.evdi_open.restype             = ctypes.c_void_p
lib.evdi_open.argtypes            = [ctypes.c_int]
lib.evdi_connect.restype          = None
lib.evdi_connect.argtypes         = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_uint,
                                      ctypes.POINTER(ctypes.c_uint32), ctypes.c_uint]
lib.evdi_disconnect.restype       = None
lib.evdi_disconnect.argtypes      = [ctypes.c_void_p]
lib.evdi_close.restype            = None
lib.evdi_close.argtypes           = [ctypes.c_void_p]
lib.evdi_get_event_ready.restype  = ctypes.c_int
lib.evdi_get_event_ready.argtypes = [ctypes.c_void_p]
lib.evdi_handle_events.restype    = None
lib.evdi_handle_events.argtypes   = [ctypes.c_void_p, ctypes.POINTER(EventCtx)]
lib.evdi_register_buffer.restype  = None
lib.evdi_register_buffer.argtypes = [ctypes.c_void_p, Buffer]
lib.evdi_unregister_buffer.restype  = None
lib.evdi_unregister_buffer.argtypes = [ctypes.c_void_p, ctypes.c_int]
lib.evdi_grab_pixels.restype      = None
lib.evdi_grab_pixels.argtypes     = [ctypes.c_void_p, ctypes.POINTER(Rect), ctypes.POINTER(ctypes.c_int)]

# ---------- EDID 1920x1080 @ 60Hz ----------
def make_edid():
    e = bytearray(128)
    e[0:8]    = b'\x00\xff\xff\xff\xff\xff\xff\x00'
    e[8:10]   = b'\x2b\xd1'
    e[10:16]  = b'\x00' * 6
    e[16] = 0x01; e[17] = 0x18
    e[18] = 0x01; e[19] = 0x03
    e[20] = 0x80; e[21] = 0x22; e[22] = 0x13
    e[23] = 0x78; e[24] = 0x0a
    e[25:35]  = b'\xee\x91\xa3\x54\x4c\x99\x26\x0f\x50\x54'
    e[35:38]  = b'\x00\x00\x00'
    e[38:54]  = b'\x01' * 16
    e[54:72]  = bytes([0x02,0x3a,0x80,0x18,0x71,0x38,0x2d,0x40,
                       0x58,0x2c,0x45,0x00,0xf4,0x19,0x00,0x00,0x00,0x1e])
    e[72:90]  = bytes([0x00,0x00,0x00,0xfc,0x00,
                       0x56,0x69,0x72,0x74,0x75,0x61,0x6c,0x0a,
                       0x20,0x20,0x20,0x20,0x20])
    e[90:108] = bytes([0x00,0x00,0x00,0xff,0x00,
                       0x56,0x44,0x44,0x30,0x30,0x31,0x0a,
                       0x20,0x20,0x20,0x20,0x20,0x20])
    e[108:126]= bytes([0x00,0x00,0x00,0xfd,0x00,
                       0x32,0x4b,0x1e,0x5a,0x11,0x00,
                       0x0a,0x20,0x20,0x20,0x20,0x20,0x20])
    e[126] = 0x00
    e[127] = (256 - sum(e[:127]) % 256) % 256
    return bytes(e)

# ---------- estado ----------
handle     = None
buf_data   = None
buf_active = False

def setup_buf(w, h):
    global buf_data, buf_active
    if buf_active:
        lib.evdi_unregister_buffer(handle, ctypes.c_int(BUF_ID))
    stride   = w * 4
    buf_data = (ctypes.c_uint8 * (stride * h))()
    rects    = (Rect * MAX_RECTS)()
    b        = Buffer()
    b.id     = BUF_ID
    b.buffer = ctypes.cast(buf_data, ctypes.c_void_p)
    b.width  = w; b.height = h; b.stride = stride
    b.rects  = rects; b.rect_count = MAX_RECTS
    lib.evdi_register_buffer(handle, b)
    buf_active = True
    print(f"  buffer registrado: {w}x{h}", flush=True)

def on_mode(mode, _):
    print(f"  modo: {mode.width}x{mode.height} @ {mode.refresh_rate}Hz", flush=True)
    setup_buf(mode.width, mode.height)

def on_update(_, __):
    if not buf_active:
        return
    rects = (Rect * MAX_RECTS)()
    n     = ctypes.c_int(MAX_RECTS)
    lib.evdi_grab_pixels(handle, rects, ctypes.byref(n))

def on_dpms(m, _): pass
def on_crtc(s, _): pass

cb_dpms   = DpmsHandlerType(on_dpms)
cb_mode   = ModeChangedType(on_mode)
cb_update = UpdateReadyType(on_update)
cb_crtc   = CrtcStateType(on_crtc)

def shutdown(sig=None, frame=None):
    print("\nevdi-daemon: desconectando display virtual...", flush=True)
    if buf_active:
        lib.evdi_unregister_buffer(handle, ctypes.c_int(BUF_ID))
    lib.evdi_disconnect(handle)
    lib.evdi_close(handle)
    sys.exit(0)

def main():
    global handle

    device = None
    for i in range(0, 16):
        if lib.evdi_check_device(ctypes.c_int(i)) == EVDI_AVAILABLE:
            device = i
            break

    if device is None:
        sys.exit("ERRO: nenhum dispositivo evdi disponível. Execute 'bsd monitor-setup' primeiro.")

    print(f"evdi-daemon: abrindo /dev/dri/card{device}", flush=True)
    handle = lib.evdi_open(ctypes.c_int(device))
    if not handle:
        sys.exit(
            f"ERRO: sem permissão para abrir /dev/dri/card{device}.\n"
            "Execute: sudo usermod -aG video $USER  (depois faça logout/login)"
        )

    edid  = make_edid()
    pfmts = (ctypes.c_uint32 * 2)(0x34325258, 0x34325241)
    lib.evdi_connect(handle, edid, len(edid), pfmts, 2)

    ctx                       = EventCtx()
    ctx.dpms_handler         = cb_dpms
    ctx.mode_changed_handler = cb_mode
    ctx.update_ready_handler = cb_update
    ctx.crtc_state_handler   = cb_crtc

    event_fd = lib.evdi_get_event_ready(handle)
    print(f"evdi-daemon: display virtual conectado (fd={event_fd})", flush=True)
    print("  Aguardando GNOME reconhecer o monitor...", flush=True)

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    while True:
        r, _, _ = select.select([event_fd], [], [], 1.0)
        if r:
            lib.evdi_handle_events(handle, ctypes.byref(ctx))

if __name__ == '__main__':
    main()
