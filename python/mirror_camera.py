"""
╔══════════════════════════════════════════════════════════════════╗
║           MIRRIFY — Espelho Inteligente (Câmera Python)         ║
║   Lumière Cosméticos • Fábrica do Futuro • Projeto 2026        ║
╚══════════════════════════════════════════════════════════════════╝

Este script abre a webcam e funciona como o "espelho inteligente"
do produto Mirrify. A pessoa se vê na tela e pode sobrepor visuais
do catálogo (maquiagens, cortes, cores de cabelo) em tempo real.

Controles:
  ← →       Trocar visual do catálogo
  ↑ ↓       Ajustar intensidade do overlay (opacidade)
  L         Trocar iluminação NeoPixel (cor da moldura)
  S         Salvar visual na galeria pessoal
  M         Espelhar / desespelhar câmera
  F         Tela cheia
  ESC / Q   Fechar espelho

Requisitos: pip install -r requirements.txt
"""

import cv2
import numpy as np
import os
import sys
import json
import time
import urllib.request
from pathlib import Path

# ─── PALETA MIRRIFY ──────────────────────────────────────────────────────────
MINT       = (237, 247, 235)       # #EBF7ED  (BGR → RGB convertido abaixo)
LAVENDER   = (237, 183, 205)       # #CDB7ED
PERIWINKLE = (228, 151, 120)       # #7897E4
VIOLET     = (241, 136, 166)       # #A688F1
TEXT_DARK  = (72, 36, 44)          # #2C2448
WHITE      = (255, 255, 255)

# Converter para BGR (OpenCV usa BGR)
def hex_to_bgr(hex_color: str):
    h = hex_color.lstrip('#')
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return (b, g, r)

MINT_BGR       = hex_to_bgr("#EBF7ED")
LAVENDER_BGR   = hex_to_bgr("#CDB7ED")
PERIWINKLE_BGR = hex_to_bgr("#7897E4")
VIOLET_BGR     = hex_to_bgr("#A688F1")
TEXT_BGR       = hex_to_bgr("#2C2448")
DARK_BG_BGR    = hex_to_bgr("#13111C")

# ─── CATÁLOGO DE VISUAIS ─────────────────────────────────────────────────────
CATALOG = [
    {
        "id": "1",
        "name": "Make Glamour Dourada",
        "category": "Maquiagem",
        "image_url": "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&auto=format&fit=crop&q=60",
    },
    {
        "id": "2",
        "name": "Morena Iluminada Mel",
        "category": "Cores de Cabelo",
        "image_url": "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&auto=format&fit=crop&q=60",
    },
    {
        "id": "3",
        "name": "Batom Vermelho Clássico",
        "category": "Maquiagem",
        "image_url": "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&auto=format&fit=crop&q=60",
    },
    {
        "id": "4",
        "name": "Corte Bob Francês Moderno",
        "category": "Cortes",
        "image_url": "https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=400&auto=format&fit=crop&q=60",
    },
    {
        "id": "5",
        "name": "Loiro Champagne Platinado",
        "category": "Cores de Cabelo",
        "image_url": "https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&auto=format&fit=crop&q=60",
    },
    {
        "id": "6",
        "name": "Cachos Definidos & Volume",
        "category": "Penteados",
        "image_url": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=60",
    },
]

# ─── MODOS DE ILUMINAÇÃO NEOPIXEL ────────────────────────────────────────────
NEOPIXEL_MODES = [
    {"name": "Natural (4500K)",  "color": hex_to_bgr("#FBF6E9")},
    {"name": "Quente (3000K)",   "color": hex_to_bgr("#FFE0B2")},
    {"name": "Fria (6000K)",     "color": hex_to_bgr("#E1F5FE")},
    {"name": "Sunset Glamour",   "color": hex_to_bgr("#FFCDD2")},
    {"name": "Lilas Dreamy",     "color": hex_to_bgr("#EDE7F6")},
    {"name": "Desligado",        "color": hex_to_bgr("#222222")},
]

# ─── HELPERS ──────────────────────────────────────────────────────────────────
CACHE_DIR = Path(__file__).parent / ".cache_images"
GALLERY_FILE = Path(__file__).parent / "minha_galeria.json"


def ensure_cache_dir():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)


def download_image(url: str, item_id: str) -> np.ndarray | None:
    """Baixa imagem da URL e armazena em cache local."""
    ensure_cache_dir()
    cache_path = CACHE_DIR / f"{item_id}.jpg"

    if cache_path.exists():
        img = cv2.imread(str(cache_path))
        if img is not None:
            return img

    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        resp = urllib.request.urlopen(req, timeout=8)
        data = np.frombuffer(resp.read(), dtype=np.uint8)
        img = cv2.imdecode(data, cv2.IMREAD_COLOR)
        if img is not None:
            cv2.imwrite(str(cache_path), img)
        return img
    except Exception as e:
        print(f"[Mirrify] Erro ao baixar imagem {item_id}: {e}")
        return None


def load_gallery() -> list[str]:
    if GALLERY_FILE.exists():
        with open(GALLERY_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return []


def save_gallery(gallery: list[str]):
    with open(GALLERY_FILE, "w", encoding="utf-8") as f:
        json.dump(gallery, f, ensure_ascii=False, indent=2)


def put_text_centered(frame, text, y, font_scale=0.6, color=WHITE,
                       thickness=1, font=cv2.FONT_HERSHEY_SIMPLEX):
    """Desenha texto centralizado horizontalmente."""
    (tw, th), _ = cv2.getTextSize(text, font, font_scale, thickness)
    x = (frame.shape[1] - tw) // 2
    cv2.putText(frame, text, (x, y), font, font_scale, color, thickness, cv2.LINE_AA)


def draw_rounded_rect(img, pt1, pt2, color, radius=20, thickness=-1):
    """Desenha retângulo com cantos arredondados."""
    x1, y1 = pt1
    x2, y2 = pt2
    cv2.rectangle(img, (x1 + radius, y1), (x2 - radius, y2), color, thickness, cv2.LINE_AA)
    cv2.rectangle(img, (x1, y1 + radius), (x2, y2 - radius), color, thickness, cv2.LINE_AA)
    cv2.circle(img, (x1 + radius, y1 + radius), radius, color, thickness, cv2.LINE_AA)
    cv2.circle(img, (x2 - radius, y1 + radius), radius, color, thickness, cv2.LINE_AA)
    cv2.circle(img, (x1 + radius, y2 - radius), radius, color, thickness, cv2.LINE_AA)
    cv2.circle(img, (x2 - radius, y2 - radius), radius, color, thickness, cv2.LINE_AA)


# ─── CLASSE PRINCIPAL DO ESPELHO ──────────────────────────────────────────────
class MirrifyMirror:
    WINDOW_NAME = "MIRRIFY - Espelho Inteligente"
    BORDER_SIZE = 18  # Largura da moldura NeoPixel

    def __init__(self):
        self.cap = None
        self.running = False
        self.mirrored = True
        self.fullscreen = False

        # Catálogo
        self.catalog = CATALOG
        self.current_index = 0
        self.overlay_opacity = 0.45  # 0.0 = só câmera, 1.0 = só visual
        self.visual_images: dict[str, np.ndarray | None] = {}

        # Iluminação NeoPixel
        self.neopixel_index = 0

        # Galeria
        self.gallery: list[str] = load_gallery()

        # Notificação temporária
        self._notification = ""
        self._notification_time = 0.0

    @property
    def current_visual(self):
        return self.catalog[self.current_index]

    @property
    def neopixel(self):
        return NEOPIXEL_MODES[self.neopixel_index]

    def show_notification(self, msg: str, duration: float = 2.5):
        self._notification = msg
        self._notification_time = time.time() + duration

    def preload_images(self):
        """Baixa todas as imagens do catálogo em background."""
        print("[Mirrify] Carregando imagens do catálogo...")
        for item in self.catalog:
            img = download_image(item["image_url"], item["id"])
            self.visual_images[item["id"]] = img
            status = "OK" if img is not None else "FALHA"
            print(f"  [{status}] {item['name']}")
        print("[Mirrify] Catálogo carregado!\n")

    def open_camera(self) -> bool:
        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            # Tenta câmera 1
            self.cap = cv2.VideoCapture(1)
        if not self.cap.isOpened():
            print("[Mirrify] ERRO: Nenhuma webcam disponível!")
            return False

        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        print(f"[Mirrify] Câmera aberta: {int(self.cap.get(cv2.CAP_PROP_FRAME_WIDTH))}x{int(self.cap.get(cv2.CAP_PROP_FRAME_HEIGHT))}")
        return True

    def draw_neopixel_border(self, frame: np.ndarray) -> np.ndarray:
        """Desenha a moldura iluminada (simulação do anel NeoPixel)."""
        b = self.BORDER_SIZE
        color = self.neopixel["color"]
        h, w = frame.shape[:2]

        # Moldura sólida
        bordered = cv2.copyMakeBorder(frame, b, b, b, b,
                                       cv2.BORDER_CONSTANT, value=color)

        # Glow suave (brilho externo)
        glow_size = b // 2
        if glow_size > 0 and color != hex_to_bgr("#222222"):
            outer = cv2.copyMakeBorder(bordered, glow_size, glow_size, glow_size, glow_size,
                                        cv2.BORDER_CONSTANT, value=(0, 0, 0))
            # Criar glow
            mask = np.zeros_like(outer, dtype=np.uint8)
            mask[glow_size:glow_size + bordered.shape[0],
                 glow_size:glow_size + bordered.shape[1]] = bordered
            blurred = cv2.GaussianBlur(mask, (0, 0), sigmaX=glow_size * 2)
            bordered = cv2.addWeighted(outer, 0.3, blurred, 0.7, 0)
            # Colocar o frame original de volta no centro
            bordered[glow_size:glow_size + b + h + b,
                     glow_size:glow_size + b + w + b] = cv2.copyMakeBorder(
                frame, b, b, b, b, cv2.BORDER_CONSTANT, value=color)

        return bordered

    def overlay_visual(self, frame: np.ndarray) -> np.ndarray:
        """Sobrepõe o visual selecionado sobre o frame da câmera."""
        item = self.current_visual
        img = self.visual_images.get(item["id"])

        if img is None or self.overlay_opacity <= 0.01:
            return frame

        h, w = frame.shape[:2]
        resized = cv2.resize(img, (w, h), interpolation=cv2.INTER_AREA)

        blended = cv2.addWeighted(
            frame, 1.0 - self.overlay_opacity,
            resized, self.overlay_opacity,
            0
        )
        return blended

    def draw_hud(self, frame: np.ndarray) -> np.ndarray:
        """Desenha a interface do espelho (HUD) sobre o frame."""
        h, w = frame.shape[:2]
        overlay = frame.copy()

        # ─── Barra superior: nome do visual ativo ─────────────────────────
        bar_h = 50
        cv2.rectangle(overlay, (0, 0), (w, bar_h), (0, 0, 0), -1)
        frame = cv2.addWeighted(overlay, 0.7, frame, 0.3, 0)

        # Sparkle (estrela simplificada)
        sparkle_x, sparkle_y = 20, 25
        pts = np.array([
            [sparkle_x, sparkle_y - 8],
            [sparkle_x + 3, sparkle_y - 3],
            [sparkle_x + 8, sparkle_y],
            [sparkle_x + 3, sparkle_y + 3],
            [sparkle_x, sparkle_y + 8],
            [sparkle_x - 3, sparkle_y + 3],
            [sparkle_x - 8, sparkle_y],
            [sparkle_x - 3, sparkle_y - 3],
        ], np.int32)
        cv2.fillPoly(frame, [pts], VIOLET_BGR)

        item = self.current_visual
        is_saved = item["id"] in self.gallery

        # Título
        cv2.putText(frame, f"MIRRIFY", (36, 22),
                     cv2.FONT_HERSHEY_SIMPLEX, 0.5, LAVENDER_BGR, 1, cv2.LINE_AA)
        cv2.putText(frame, f"{item['name']}  |  {item['category']}",
                     (36, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.45, WHITE, 1, cv2.LINE_AA)

        # Badge salvo
        if is_saved:
            cv2.putText(frame, "[SALVO]", (w - 90, 32),
                         cv2.FONT_HERSHEY_SIMPLEX, 0.45, (180, 100, 255), 1, cv2.LINE_AA)

        # Opacidade à direita
        opacity_pct = int(self.overlay_opacity * 100)
        cv2.putText(frame, f"Intensidade: {opacity_pct}%", (w - 200, 20),
                     cv2.FONT_HERSHEY_SIMPLEX, 0.4, LAVENDER_BGR, 1, cv2.LINE_AA)

        # ─── Barra inferior: controles e NeoPixel ────────────────────────
        bar_bottom_y = h - 55
        bottom_overlay = frame.copy()
        cv2.rectangle(bottom_overlay, (0, bar_bottom_y), (w, h), (0, 0, 0), -1)
        frame = cv2.addWeighted(bottom_overlay, 0.65, frame, 0.35, 0)

        # Instruções
        controls = "[<- ->] Visual   [Setas cima/baixo] Intensidade   [L] Luz   [S] Salvar   [M] Espelhar   [F] Fullscreen   [ESC] Sair"
        cv2.putText(frame, controls, (12, h - 35),
                     cv2.FONT_HERSHEY_SIMPLEX, 0.33, (180, 180, 180), 1, cv2.LINE_AA)

        # NeoPixel mode
        neo_name = self.neopixel["name"]
        neo_color = self.neopixel["color"]
        cv2.putText(frame, f"NeoPixel: {neo_name}", (12, h - 12),
                     cv2.FONT_HERSHEY_SIMPLEX, 0.4, neo_color, 1, cv2.LINE_AA)

        # Indicador de posição no catálogo
        pos_text = f"{self.current_index + 1}/{len(self.catalog)}"
        cv2.putText(frame, pos_text, (w - 60, h - 12),
                     cv2.FONT_HERSHEY_SIMPLEX, 0.45, PERIWINKLE_BGR, 1, cv2.LINE_AA)

        # ─── Notificação pop-up ───────────────────────────────────────────
        if self._notification and time.time() < self._notification_time:
            notif_h = 45
            notif_y = h // 2 - notif_h // 2
            notif_overlay = frame.copy()
            cv2.rectangle(notif_overlay, (40, notif_y), (w - 40, notif_y + notif_h),
                           VIOLET_BGR, -1)
            frame = cv2.addWeighted(notif_overlay, 0.85, frame, 0.15, 0)
            put_text_centered(frame, self._notification, notif_y + 30,
                               font_scale=0.6, color=WHITE, thickness=2)

        # ─── Setas de navegação laterais ──────────────────────────────────
        arrow_y = h // 2
        # Seta esquerda
        cv2.arrowedLine(frame, (45, arrow_y), (20, arrow_y),
                         LAVENDER_BGR, 2, tipLength=0.5)
        # Seta direita
        cv2.arrowedLine(frame, (w - 45, arrow_y), (w - 20, arrow_y),
                         LAVENDER_BGR, 2, tipLength=0.5)

        return frame

    def handle_key(self, key: int) -> bool:
        """Processa tecla pressionada. Retorna False para sair."""
        if key == -1:
            return True

        # ESC ou Q = sair
        if key == 27 or key == ord('q') or key == ord('Q'):
            return False

        # ← Anterior
        if key == 81 or key == 2424832 or key == ord(','):  # LEFT arrow
            self.current_index = (self.current_index - 1) % len(self.catalog)
            self.show_notification(f"<< {self.current_visual['name']}")

        # → Próximo
        elif key == 83 or key == 2555904 or key == ord('.'):  # RIGHT arrow
            self.current_index = (self.current_index + 1) % len(self.catalog)
            self.show_notification(f">> {self.current_visual['name']}")

        # ↑ Aumentar opacidade
        elif key == 82 or key == 2490368:  # UP arrow
            self.overlay_opacity = min(1.0, self.overlay_opacity + 0.05)

        # ↓ Diminuir opacidade
        elif key == 84 or key == 2621440:  # DOWN arrow
            self.overlay_opacity = max(0.0, self.overlay_opacity - 0.05)

        # L = NeoPixel
        elif key == ord('l') or key == ord('L'):
            self.neopixel_index = (self.neopixel_index + 1) % len(NEOPIXEL_MODES)
            self.show_notification(f"NeoPixel: {self.neopixel['name']}")

        # S = Salvar/remover galeria
        elif key == ord('s') or key == ord('S'):
            item_id = self.current_visual["id"]
            if item_id in self.gallery:
                self.gallery.remove(item_id)
                save_gallery(self.gallery)
                self.show_notification("Removido da galeria")
            else:
                self.gallery.append(item_id)
                save_gallery(self.gallery)
                self.show_notification(f"Salvo na galeria! ({len(self.gallery)} visuais)")

        # M = Espelhar
        elif key == ord('m') or key == ord('M'):
            self.mirrored = not self.mirrored
            status = "Espelhado" if self.mirrored else "Normal"
            self.show_notification(f"Câmera: {status}")

        # F = Tela cheia
        elif key == ord('f') or key == ord('F'):
            self.fullscreen = not self.fullscreen
            if self.fullscreen:
                cv2.setWindowProperty(self.WINDOW_NAME,
                                       cv2.WND_PROP_FULLSCREEN,
                                       cv2.WINDOW_FULLSCREEN)
            else:
                cv2.setWindowProperty(self.WINDOW_NAME,
                                       cv2.WND_PROP_FULLSCREEN,
                                       cv2.WINDOW_NORMAL)

        return True

    def run(self):
        """Loop principal do Espelho Inteligente Mirrify."""
        print("=" * 60)
        print("   MIRRIFY — Espelho Inteligente")
        print("   Lumière Cosméticos • Fábrica do Futuro")
        print("=" * 60)
        print()

        # Pré-carregar imagens do catálogo
        self.preload_images()

        # Abrir câmera
        if not self.open_camera():
            print("\n[ERRO] Não foi possível abrir a webcam.")
            print("Dicas:")
            print("  - Feche outros apps que usam a câmera (Zoom, Meet, Discord)")
            print("  - Verifique se a webcam está conectada")
            print("  - Tente reiniciar o computador")
            input("\nPressione Enter para sair...")
            return

        # Criar janela
        cv2.namedWindow(self.WINDOW_NAME, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(self.WINDOW_NAME, 960, 720)

        self.running = True
        self.show_notification("Bem-vindo(a) ao Mirrify! Use as setas para navegar.", 4.0)

        print("[Mirrify] Espelho ativo! Controles:")
        print("  ← →       Trocar visual")
        print("  ↑ ↓       Ajustar intensidade do overlay")
        print("  L         Trocar iluminação NeoPixel")
        print("  S         Salvar / remover da galeria")
        print("  M         Espelhar / desespelhar")
        print("  F         Tela cheia")
        print("  ESC / Q   Fechar")
        print()

        while self.running:
            ret, frame = self.cap.read()
            if not ret:
                print("[Mirrify] Erro ao capturar frame da câmera")
                break

            # Espelhar (como um espelho de verdade)
            if self.mirrored:
                frame = cv2.flip(frame, 1)

            # Overlay do visual
            frame = self.overlay_visual(frame)

            # HUD (interface do espelho)
            frame = self.draw_hud(frame)

            # Moldura NeoPixel
            frame = self.draw_neopixel_border(frame)

            # Exibir
            cv2.imshow(self.WINDOW_NAME, frame)

            # Processar teclas
            key = cv2.waitKey(1) & 0xFF
            if not self.handle_key(key):
                break

            # Verifica se a janela foi fechada pelo X
            if cv2.getWindowProperty(self.WINDOW_NAME, cv2.WND_PROP_VISIBLE) < 1:
                break

        # Limpeza
        self.cap.release()
        cv2.destroyAllWindows()
        print("\n[Mirrify] Espelho fechado. Até a próxima! ✨")


# ─── ENTRADA ──────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    mirror = MirrifyMirror()
    mirror.run()
