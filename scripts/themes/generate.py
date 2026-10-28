import json
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "themes")

def blend(fg, bg, alpha):
    f = [int(fg[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(bg[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(fc * alpha + bc * (1 - alpha)):02x}" for fc, bc in zip(f, b))

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
        herdr_accent="#a89984", label="Gruvbox Material", nvim="gruvbox-material",
        bg="#282828", bg1="#32302f", bg2="#45403d", subtle="#5a524c", gray="#928374", fg="#d4be98",
        red="#ea6962", orange="#e78a4e", yellow="#d8a657", green="#a9b665", aqua="#89b482", blue="#7daea3", purple="#d3869b",
        selection="#45403d", cursor="#d4be98",
        ansi=["#5a524c", "#ea6962", "#a9b665", "#d8a657", "#7daea3", "#d3869b", "#89b482", "#d4be98",
              "#5a524c", "#ea6962", "#a9b665", "#d8a657", "#7daea3", "#d3869b", "#89b482", "#d4be98"],
    ),
    "everforest": dict(
        herdr_accent="#9da9a0", label="Everforest Dark", nvim="everforest",
        bg="#2d353b", bg1="#343f44", bg2="#3d484d", subtle="#475258", gray="#859289", fg="#d3c6aa",
        red="#e67e80", orange="#e69875", yellow="#dbbc7f", green="#a7c080", aqua="#83c092", blue="#7fbbb3", purple="#d699b6",
        selection="#543a48", cursor="#d3c6aa",
        ansi=["#475258", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa",
              "#475258", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa"],
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
        bg="#2e3440", bg1="#3b4252", bg2="#434c5e", subtle="#4c566a", gray="#616e88", fg="#d8dee9",
        red="#bf616a", orange="#d08770", yellow="#ebcb8b", green="#a3be8c", aqua="#8fbcbb", blue="#81a1c1", purple="#b48ead",
        selection="#434c5e", cursor="#d8dee9",
        ansi=["#3b4252", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#88c0d0", "#e5e9f0",
              "#4c566a", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#8fbcbb", "#eceff4"],
    ),
}

for theme_id, t in THEMES.items():
    folder = os.path.join(OUT, theme_id)
    os.makedirs(folder, exist_ok=True)

    with open(os.path.join(folder, "theme.conf"), "w") as f:
        f.write(f'label="{t["label"]}"\nnvim_colorscheme="{t["nvim"]}"\n')

    ghostty = [f"background = {t['bg'][1:]}", f"foreground = {t['fg'][1:]}", ""]
    ghostty += [f"palette = {i}={c}" for i, c in enumerate(t["ansi"])]
    ghostty += ["", f"selection-background = {t['selection'][1:]}", f"selection-foreground = {t['fg'][1:]}",
                f"cursor-color = {t['cursor'][1:]}", f"split-divider-color = {t['bg2'][1:]}"]
    with open(os.path.join(folder, "ghostty"), "w") as f:
        f.write("\n".join(ghostty) + "\n")

    fzf_colors = ",".join([
        f"fg:{t['fg']}", "bg:-1", f"hl:{t['blue']}", f"fg+:{t['fg']}", f"bg+:{t['bg1']}", f"hl+:{t['aqua']}",
        f"info:{t['gray']}", f"prompt:{t['purple']}", f"pointer:{t['yellow']}", f"marker:{t['green']}",
        f"spinner:{t['purple']}", f"header:{t['gray']}", f"border:{t['subtle']}", "gutter:-1",
    ])
    with open(os.path.join(folder, "fzf"), "w") as f:
        f.write(f"--color={fzf_colors}\n")

    herdr = [
        "[theme.custom]",
        f'accent = "{t["herdr_accent"]}"',
        f'panel_bg = "{t["bg"]}"',
        f'active_row_bg = "{t["bg1"]}"',
        f'selection_bg = "{t["bg2"]}"',
    ]
    with open(os.path.join(folder, "herdr"), "w") as f:
        f.write("\n".join(herdr) + "\n")

    bg = t["bg"]
    claude = {
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
    with open(os.path.join(folder, "claude.json"), "w") as f:
        json.dump(claude, f, indent=2)
        f.write("\n")

print("generated", ", ".join(THEMES))
