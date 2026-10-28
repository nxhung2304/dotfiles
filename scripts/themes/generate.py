import json
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "themes")

MIN_TEXT_CONTRAST = 4.5
MIN_DIM_TEXT_CONTRAST = 3.0


def blend(fg, bg, alpha):
    f = [int(fg[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(bg[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(fc * alpha + bc * (1 - alpha)):02x}" for fc, bc in zip(f, b))


GRUVBOX_MATERIAL_ACCENTS = dict(
    fg="#d4be98", gray="#928374",
    red="#ea6962", orange="#e78a4e", yellow="#d8a657", green="#a9b665", aqua="#89b482", blue="#7daea3", purple="#d3869b",
    cursor="#d4be98", herdr_accent="#a89984", nvim="gruvbox-material",
)


def gruvbox_material_ansi(black):
    colors = [black, "#ea6962", "#a9b665", "#d8a657", "#7daea3", "#d3869b", "#89b482", "#d4be98"]
    return colors + colors


EVERFOREST_ACCENTS = dict(
    fg="#d3c6aa", gray="#859289",
    red="#e67e80", orange="#e69875", yellow="#dbbc7f", green="#a7c080", aqua="#83c092", blue="#7fbbb3", purple="#d699b6",
    cursor="#d3c6aa", herdr_accent="#9da9a0", nvim="everforest",
)


def everforest_ansi(black):
    colors = [black, "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa"]
    return colors + colors


ZENBONES_ACCENTS = dict(
    red="#de6e7c", orange="#d68c67", yellow="#b77e64", green="#819b69", aqua="#66a5ad", blue="#6099c0", purple="#b279a7",
)

ZENBONES_ANSI_COLORS = ["#de6e7c", "#819b69", "#b77e64", "#6099c0", "#b279a7", "#66a5ad"]
ZENBONES_ANSI_BRIGHT_COLORS = ["#e8838f", "#8bae68", "#d68c67", "#61abda", "#cf86c1", "#65b8c1"]

THEMES = {
    "gruvbox": dict(
        herdr_accent="#a89984", label="Gruvbox Dark", nvim="gruvbox",
        bg="#282828", bg1="#3c3836", bg2="#504945", subtle="#665c54", gray="#928374", fg="#ebdbb2",
        red="#fb4934", orange="#fe8019", yellow="#fabd2f", green="#b8bb26", aqua="#8ec07c", blue="#83a598", purple="#d3869b",
        selection="#504945", cursor="#ebdbb2",
        ansi=["#282828", "#cc241d", "#98971a", "#d79921", "#458588", "#b16286", "#689d6a", "#a89984",
              "#928374", "#fb4934", "#b8bb26", "#fabd2f", "#83a598", "#d3869b", "#8ec07c", "#ebdbb2"],
    ),
    "gruvbox-material": dict(
        GRUVBOX_MATERIAL_ACCENTS, label="Gruvbox Material",
        nvim_globals={"gruvbox_material_background": "medium"},
        bg="#282828", bg1="#32302f", bg2="#45403d", subtle="#5a524c", selection="#45403d",
        ansi=gruvbox_material_ansi("#5a524c"),
    ),
    "gruvbox-material-hard": dict(
        GRUVBOX_MATERIAL_ACCENTS, label="Gruvbox Material Hard",
        nvim_globals={"gruvbox_material_background": "hard"},
        bg="#1d2021", bg1="#282828", bg2="#3c3836", subtle="#504945", selection="#3c3836",
        ansi=gruvbox_material_ansi("#504945"),
    ),
    "gruvbox-material-soft": dict(
        GRUVBOX_MATERIAL_ACCENTS, label="Gruvbox Material Soft",
        nvim_globals={"gruvbox_material_background": "soft"},
        bg="#32302f", bg1="#3c3836", bg2="#504945", subtle="#665c54", selection="#504945",
        ansi=gruvbox_material_ansi("#665c54"),
    ),
    "everforest": dict(
        EVERFOREST_ACCENTS, label="Everforest Dark",
        nvim_globals={"everforest_background": "medium"},
        bg="#2d353b", bg1="#343f44", bg2="#3d484d", subtle="#475258", selection="#543a48",
        ansi=everforest_ansi("#475258"),
    ),
    "everforest-hard": dict(
        EVERFOREST_ACCENTS, label="Everforest Dark Hard",
        nvim_globals={"everforest_background": "hard"},
        bg="#272e33", bg1="#2e383c", bg2="#374145", subtle="#414b50", selection="#4c3743",
        ansi=everforest_ansi("#414b50"),
    ),
    "arctic": dict(
        herdr_accent="#9d9d9d", label="Arctic", nvim="arctic",
        bg="#1f1f1f", bg1="#2d2d2d", bg2="#3c3c3c", subtle="#454545", gray="#808080", fg="#cccccc",
        red="#f44747", orange="#ce9178", yellow="#dcdcaa", green="#6a9955", aqua="#4ec9b0", blue="#569cd6", purple="#c586c0",
        selection="#264f78", cursor="#cccccc",
        ansi=["#1f1f1f", "#f44747", "#6a9955", "#d7ba7d", "#569cd6", "#c586c0", "#4dc9b0", "#dddddd",
              "#808080", "#f55757", "#80ad6b", "#e1cb9e", "#6fabdc", "#d6a9d2", "#70d3bf", "#ffffff"],
    ),
    "nord": dict(
        herdr_accent="#81a1c1", label="Nord", nvim="nord",
        bg="#2e3440", bg1="#3b4252", bg2="#434c5e", subtle="#4c566a", gray=blend("#d8dee9", "#2e3440", 0.45), fg="#d8dee9",
        red="#bf616a", orange="#d08770", yellow="#ebcb8b", green="#a3be8c", aqua="#8fbcbb", blue="#81a1c1", purple="#b48ead",
        selection="#434c5e", cursor="#d8dee9",
        ansi=["#3b4252", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#88c0d0", "#e5e9f0",
              "#4c566a", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#8fbcbb", "#eceff4"],
    ),
    "zenbones": dict(
        ZENBONES_ACCENTS, herdr_accent="#888f94", label="Zenbones", nvim="zenbones",
        bg="#1c1917", bg1=blend("#b4bdc3", "#1c1917", 0.07), bg2="#3d4042", subtle="#403833", gray="#888f94", fg="#b4bdc3",
        selection="#3d4042", cursor="#c4cacf",
        ansi=["#1c1917", *ZENBONES_ANSI_COLORS, "#b4bdc3", "#403833", *ZENBONES_ANSI_BRIGHT_COLORS, "#888f94"],
    ),
    "zenwritten": dict(
        ZENBONES_ACCENTS, herdr_accent="#8e8e8e", label="Zenwritten", nvim="zenwritten",
        bg="#191919", bg1=blend("#bbbbbb", "#191919", 0.07), bg2="#404040", subtle="#3d3839", gray="#8e8e8e", fg="#bbbbbb",
        selection="#404040", cursor="#c9c9c9",
        ansi=["#191919", *ZENBONES_ANSI_COLORS, "#bbbbbb", "#3d3839", *ZENBONES_ANSI_BRIGHT_COLORS, "#8e8e8e"],
    ),
    "melange": dict(
        herdr_accent="#c1a78e", label="Melange", nvim="melange",
        bg="#292522", bg1="#34302c", bg2="#403a36", subtle=blend("#ece1d7", "#292522", 0.2), gray="#867462", fg="#ece1d7",
        red="#bd8183", orange="#e49b5d", yellow="#ebc06d", green="#78997a", aqua="#7b9695", blue="#7f91b2", purple="#b380b0",
        selection="#403a36", cursor="#ece1d7",
        ansi=["#34302c", "#bd8183", "#78997a", "#e49b5d", "#7f91b2", "#b380b0", "#7b9695", "#c1a78e",
              "#867462", "#d47766", "#85b695", "#ebc06d", "#a3a9ce", "#cf9bc2", "#89b3b6", "#ece1d7"],
    ),
    "vague": dict(
        herdr_accent="#878787", label="Vague", nvim="vague",
        bg="#141415", bg1="#252530", bg2="#333738", subtle=blend("#cdcdcd", "#141415", 0.22), gray="#606079", fg="#cdcdcd",
        red="#d8647e", orange="#e8b589", yellow="#f3be7c", green="#7fa563", aqua="#b4d4cf", blue="#6e94b2", purple="#bb9dbd",
        selection="#333738", cursor="#cdcdcd",
        ansi=["#252530", "#d8647e", "#7fa563", "#f3be7c", "#6e94b2", "#bb9dbd", "#aeaed1", "#cdcdcd",
              "#606079", "#e08398", "#99b782", "#f5cb96", "#8ba9c1", "#c9b1ca", "#bebeda", "#d7d7d7"],
    ),
}


def write_file(folder, name, content):
    with open(os.path.join(folder, name), "w") as f:
        f.write(content)


def theme_conf(t):
    globals_text = " ".join(f"{name}={value}" for name, value in t.get("nvim_globals", {}).items())
    return f'label="{t["label"]}"\nnvim_colorscheme="{t["nvim"]}"\nnvim_globals="{globals_text}"\n'


def ghostty_config(t):
    lines = [f"background = {t['bg'][1:]}", f"foreground = {t['fg'][1:]}", ""]
    lines += [f"palette = {i}={c}" for i, c in enumerate(t["ansi"])]
    lines += ["", f"selection-background = {t['selection'][1:]}", f"selection-foreground = {t['fg'][1:]}",
              f"cursor-color = {t['cursor'][1:]}", f"split-divider-color = {t['bg2'][1:]}"]
    return "\n".join(lines) + "\n"


def fzf_options(t):
    colors = ",".join([
        f"fg:{t['fg']}", "bg:-1", f"hl:{t['blue']}", f"fg+:{t['fg']}", f"bg+:{t['bg1']}", f"hl+:{t['aqua']}",
        f"info:{t['gray']}", f"prompt:{t['purple']}", f"pointer:{t['yellow']}", f"marker:{t['green']}",
        f"spinner:{t['purple']}", f"header:{t['gray']}", f"border:{t['subtle']}", "gutter:-1",
    ])
    return f"--color={colors}\n"


def herdr_custom_colors(t):
    lines = [
        "[theme.custom]",
        f'accent = "{t["herdr_accent"]}"',
        f'panel_bg = "{t["bg"]}"',
        f'active_row_bg = "{t["bg1"]}"',
        f'selection_bg = "{t["bg2"]}"',
    ]
    return "\n".join(lines) + "\n"


def claude_theme(t):
    bg = t["bg"]
    theme = {
        "name": t["label"],
        "base": "dark",
        "overrides": {
            "claude": t["yellow"],
            "claudeShimmer": t["fg"],
            "text": t["fg"],
            "inverseText": bg,
            "inactive": t["gray"],
            "subtle": t["subtle"],
            "suggestion": t["blue"],
            "permission": t["aqua"],
            "remember": t["purple"],
            "success": t["green"],
            "error": t["red"],
            "warning": t["orange"],
            "merged": t["purple"],
            "promptBorder": t["subtle"],
            "planMode": t["aqua"],
            "autoAccept": t["purple"],
            "bashBorder": t["red"],
            "ide": t["blue"],
            "diffAdded": blend(t["green"], bg, 0.18),
            "diffRemoved": blend(t["red"], bg, 0.18),
            "diffAddedDimmed": blend(t["green"], bg, 0.09),
            "diffRemovedDimmed": blend(t["red"], bg, 0.09),
            "diffAddedWord": blend(t["green"], bg, 0.5),
            "diffRemovedWord": blend(t["red"], bg, 0.5),
            "userMessageBackground": t["bg1"],
            "userMessageBackgroundHover": t["bg2"],
            "selectionBg": t["selection"],
        },
    }
    return json.dumps(theme, indent=2) + "\n"


def relative_luminance(color):
    channels = []
    for i in (1, 3, 5):
        value = int(color[i:i + 2], 16) / 255
        channels.append(value / 12.92 if value <= 0.03928 else ((value + 0.055) / 1.055) ** 2.4)
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


def contrast_ratio(foreground, background):
    lighter, darker = sorted((relative_luminance(foreground), relative_luminance(background)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def contrast_warnings(theme_id, t):
    checks = [
        ("text on background", t["fg"], t["bg"], MIN_TEXT_CONTRAST),
        ("text on active row / user message", t["fg"], t["bg1"], MIN_TEXT_CONTRAST),
        ("text on selection", t["fg"], t["selection"], MIN_TEXT_CONTRAST),
        ("herdr active tab label", t["bg"], t["herdr_accent"], MIN_TEXT_CONTRAST),
        ("dim text on background", t["gray"], t["bg"], MIN_DIM_TEXT_CONTRAST),
    ]
    warnings = []
    for description, foreground, background, minimum in checks:
        ratio = contrast_ratio(foreground, background)
        if ratio < minimum:
            warnings.append(f"{theme_id}: {description} {foreground} on {background} is {ratio:.2f}:1 (min {minimum}:1)")
    return warnings


def generate(theme_id, t):
    folder = os.path.join(OUT, theme_id)
    os.makedirs(folder, exist_ok=True)
    write_file(folder, "theme.conf", theme_conf(t))
    write_file(folder, "ghostty", ghostty_config(t))
    write_file(folder, "fzf", fzf_options(t))
    write_file(folder, "herdr", herdr_custom_colors(t))
    write_file(folder, "claude.json", claude_theme(t))


all_warnings = []
for theme_id, t in THEMES.items():
    generate(theme_id, t)
    all_warnings += contrast_warnings(theme_id, t)

print("generated", ", ".join(THEMES))
for warning in all_warnings:
    print("low contrast:", warning)
