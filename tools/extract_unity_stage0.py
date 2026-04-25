from __future__ import annotations

import json
import math
import re
import struct
from pathlib import Path


UNITY_ROOT = Path(r"E:\spaceherounity\Space-Hero")
UNITY_ASSETS = UNITY_ROOT / "Assets"
UNITY_SCENE = UNITY_ASSETS / "Scenes" / "stage0.unity"
GODOT_ROOT = Path(__file__).resolve().parents[1]
OUT_PATH = GODOT_ROOT / "generated" / "unity_stage0_menu.json"


VECTOR_RE = re.compile(r"\{x:\s*([^,}]+),\s*y:\s*([^,}]+)(?:,\s*z:\s*([^,}]+))?")
COLOR_RE = re.compile(r"\{r:\s*([^,}]+),\s*g:\s*([^,}]+),\s*b:\s*([^,}]+),\s*a:\s*([^,}]+)\}")
SPRITE_RE = re.compile(r"m_Sprite:\s*\{fileID:\s*([^,}]+),\s*guid:\s*([^,}]+),")
FILE_ID_RE = re.compile(r"fileID:\s*([^,}]+)")
GUID_RE = re.compile(r"^guid:\s*([0-9a-f]+)\s*$", re.MULTILINE)
DOC_RE = re.compile(r"^--- !u!(\d+) &(-?\d+)\n", re.MULTILINE)


def parse_float(value: str) -> float:
    return float(value.strip())


def parse_vector(line: str) -> list[float]:
    match = VECTOR_RE.search(line)
    if not match:
        return [0.0, 0.0, 0.0]
    return [
        parse_float(match.group(1)),
        parse_float(match.group(2)),
        parse_float(match.group(3) or "0"),
    ]


def parse_color(line: str) -> list[float]:
    match = COLOR_RE.search(line)
    if not match:
        return [1.0, 1.0, 1.0, 1.0]
    return [parse_float(match.group(i)) for i in range(1, 5)]


def split_unity_docs(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    matches = list(DOC_RE.finditer(text))
    docs: list[dict] = []
    for index, match in enumerate(matches):
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        docs.append(
            {
                "type": int(match.group(1)),
                "id": int(match.group(2)),
                "body": text[start:end],
            }
        )
    return docs


def parse_guid_map() -> dict[str, str]:
    guid_map: dict[str, str] = {}
    for meta_path in UNITY_ASSETS.rglob("*.meta"):
        text = meta_path.read_text(encoding="utf-8", errors="ignore")
        match = GUID_RE.search(text)
        if not match:
            continue
        asset_path = meta_path.with_suffix("")
        guid_map[match.group(1)] = asset_path.relative_to(UNITY_ROOT).as_posix()
    return guid_map


def png_size(path: Path) -> tuple[int, int] | None:
    if path.suffix.lower() != ".png" or not path.exists():
        return None
    with path.open("rb") as handle:
        if handle.read(8) != b"\x89PNG\r\n\x1a\n":
            return None
        length = struct.unpack(">I", handle.read(4))[0]
        chunk_type = handle.read(4)
        if length < 13 or chunk_type != b"IHDR":
            return None
        width, height = struct.unpack(">II", handle.read(8))
    return width, height


def parse_sprite_meta(meta_path: Path) -> dict:
    text = meta_path.read_text(encoding="utf-8", errors="ignore")
    guid_match = GUID_RE.search(text)
    if not guid_match:
        return {}

    ppu_match = re.search(r"spritePixelsToUnits:\s*([0-9.]+)", text)
    pixels_per_unit = float(ppu_match.group(1)) if ppu_match else 100.0
    image_path = meta_path.with_suffix("")
    image_size = png_size(image_path)
    image_height = image_size[1] if image_size else 0
    sprites: dict[str, dict] = {}

    sprite_sheet_match = re.search(r"\n\s*spriteSheet:\n(.*?)(?:\n\s*spritePackingTag:|\Z)", text, re.S)
    sprite_sheet = sprite_sheet_match.group(1) if sprite_sheet_match else ""
    for block_match in re.finditer(r"^\s*-\s+serializedVersion:\s+2\n\s+name:\s*.+?(?=^\s*-\s+serializedVersion:\s+2\n\s+name:|\Z)", sprite_sheet, re.S | re.M):
        block = block_match.group(0)
        name_match = re.search(r"^\s*name:\s*(.+)", block, re.M)
        internal_match = re.search(r"^\s*internalID:\s*(-?\d+)", block, re.M)
        x_match = re.search(r"^\s*x:\s*([0-9.]+)", block, re.M)
        y_match = re.search(r"^\s*y:\s*([0-9.]+)", block, re.M)
        w_match = re.search(r"^\s*width:\s*([0-9.]+)", block, re.M)
        h_match = re.search(r"^\s*height:\s*([0-9.]+)", block, re.M)
        pivot_match = re.search(r"^\s*pivot:\s*\{x:\s*([^,}]+),\s*y:\s*([^,}]+)\}", block, re.M)
        if not (name_match and internal_match and x_match and y_match and w_match and h_match):
            continue

        x = float(x_match.group(1))
        y = float(y_match.group(1))
        width = float(w_match.group(1))
        height = float(h_match.group(1))
        godot_y = image_height - y - height if image_height else y
        pivot = [0.5, 0.5]
        if pivot_match:
            pivot = [float(pivot_match.group(1)), float(pivot_match.group(2))]
        sprites[internal_match.group(1)] = {
            "name": name_match.group(1).strip(),
            "rect_unity": [x, y, width, height],
            "rect_godot": [x, godot_y, width, height],
            "pivot": pivot,
        }

    if not sprites and image_size:
        sprites["21300000"] = {
            "name": image_path.stem,
            "rect_unity": [0, 0, image_size[0], image_size[1]],
            "rect_godot": [0, 0, image_size[0], image_size[1]],
            "pivot": [0.5, 0.5],
        }

    return {
        "guid": guid_match.group(1),
        "asset": image_path.relative_to(UNITY_ROOT).as_posix(),
        "pixels_per_unit": pixels_per_unit,
        "image_size": list(image_size) if image_size else None,
        "sprites": sprites,
    }


def parse_sprite_catalog() -> dict[str, dict]:
    catalog: dict[str, dict] = {}
    for meta_path in UNITY_ASSETS.rglob("*.png.meta"):
        data = parse_sprite_meta(meta_path)
        if data:
            catalog[data["guid"]] = data
    return catalog


def parse_scene(path: Path) -> tuple[dict, dict, dict, dict, dict]:
    game_objects: dict[int, dict] = {}
    transforms: dict[int, dict] = {}
    renderers: dict[int, dict] = {}
    behaviours: dict[int, dict] = {}
    cameras: dict[int, dict] = {}

    for doc in split_unity_docs(path):
        body = doc["body"]
        doc_id = doc["id"]
        if doc["type"] == 1:
            components = [int(value) for value in FILE_ID_RE.findall(body)]
            name_match = re.search(r"\n\s*m_Name:\s*(.*)", body)
            active_match = re.search(r"\n\s*m_IsActive:\s*(\d+)", body)
            game_objects[doc_id] = {
                "name": name_match.group(1).strip() if name_match else "",
                "active": active_match.group(1) == "1" if active_match else True,
                "components": components,
            }
        elif doc["type"] == 4:
            game_object = int(re.search(r"m_GameObject:\s*\{fileID:\s*(-?\d+)\}", body).group(1))
            father = int(re.search(r"m_Father:\s*\{fileID:\s*(-?\d+)\}", body).group(1))
            children_block = re.search(r"m_Children:\n((?:\s*-\s*\{fileID:\s*-?\d+\}\n)*)", body)
            children = [int(value) for value in FILE_ID_RE.findall(children_block.group(1))] if children_block else []
            order_match = re.search(r"m_RootOrder:\s*(-?\d+)", body)
            transforms[doc_id] = {
                "game_object": game_object,
                "position": parse_vector(re.search(r"m_LocalPosition:.*", body).group(0)),
                "scale": parse_vector(re.search(r"m_LocalScale:.*", body).group(0)),
                "rotation": parse_vector(re.search(r"m_LocalEulerAnglesHint:.*", body).group(0)),
                "father": father,
                "children": children,
                "root_order": int(order_match.group(1)) if order_match else 0,
            }
        elif doc["type"] == 212:
            game_object = int(re.search(r"m_GameObject:\s*\{fileID:\s*(-?\d+)\}", body).group(1))
            sprite_match = SPRITE_RE.search(body)
            order_match = re.search(r"m_SortingOrder:\s*(-?\d+)", body)
            renderers[doc_id] = {
                "game_object": game_object,
                "sorting_order": int(order_match.group(1)) if order_match else 0,
                "sprite_file_id": sprite_match.group(1).strip() if sprite_match else "0",
                "sprite_guid": sprite_match.group(2).strip() if sprite_match else "",
                "color": parse_color(re.search(r"m_Color:.*", body).group(0)) if "m_Color:" in body else [1, 1, 1, 1],
                "size": parse_vector(re.search(r"m_Size:.*", body).group(0))[:2] if "m_Size:" in body else [0, 0],
            }
        elif doc["type"] == 114:
            game_object_match = re.search(r"m_GameObject:\s*\{fileID:\s*(-?\d+)\}", body)
            if not game_object_match:
                continue
            script_match = re.search(r"m_Script:\s*\{fileID:\s*[^,]+,\s*guid:\s*([^,}]+)", body)
            values = {}
            for field in ("radius", "speed", "startAngle", "amplitude", "frequency"):
                match = re.search(rf"\n\s*{field}:\s*([-0-9.]+)", body)
                if match:
                    values[field] = float(match.group(1))
            target_match = re.search(r"\n\s*target:\s*\{fileID:\s*(-?\d+)\}", body)
            if target_match:
                values["target"] = int(target_match.group(1))
            behaviours[doc_id] = {
                "game_object": int(game_object_match.group(1)),
                "script_guid": script_match.group(1) if script_match else "",
                "values": values,
            }
        elif doc["type"] == 20:
            game_object = int(re.search(r"m_GameObject:\s*\{fileID:\s*(-?\d+)\}", body).group(1))
            ortho_match = re.search(r"orthographic size:\s*([0-9.]+)", body)
            cameras[doc_id] = {
                "game_object": game_object,
                "orthographic_size": float(ortho_match.group(1)) if ortho_match else 5.0,
            }

    return game_objects, transforms, renderers, behaviours, cameras


def combine_transform(transform_id: int, transforms: dict[int, dict], cache: dict[int, dict]) -> dict:
    if transform_id in cache:
        return cache[transform_id]

    current = transforms[transform_id]
    position = current["position"][:]
    scale = current["scale"][:]
    rotation = current["rotation"][:]
    if current["father"] in transforms:
        parent = combine_transform(current["father"], transforms, cache)
        position = [
            parent["position"][0] + position[0] * parent["scale"][0],
            parent["position"][1] + position[1] * parent["scale"][1],
            parent["position"][2] + position[2] * parent["scale"][2],
        ]
        scale = [
            parent["scale"][0] * scale[0],
            parent["scale"][1] * scale[1],
            parent["scale"][2] * scale[2],
        ]
        rotation = [
            parent["rotation"][0] + rotation[0],
            parent["rotation"][1] + rotation[1],
            parent["rotation"][2] + rotation[2],
        ]

    cache[transform_id] = {"position": position, "scale": scale, "rotation": rotation}
    return cache[transform_id]


def godot_res_path(unity_asset_path: str) -> str:
    sprite_prefix = "Assets/Sprite/"
    if unity_asset_path.startswith(sprite_prefix):
        return "res://assets/sprites/" + unity_asset_path[len(sprite_prefix) :]
    return "res://" + unity_asset_path


def main() -> None:
    guid_map = parse_guid_map()
    sprite_catalog = parse_sprite_catalog()
    game_objects, transforms, renderers, behaviours, cameras = parse_scene(UNITY_SCENE)

    transform_by_go = {data["game_object"]: transform_id for transform_id, data in transforms.items()}
    renderer_by_go = {data["game_object"]: data for data in renderers.values()}
    behaviours_by_go: dict[int, list[dict]] = {}
    for behaviour in behaviours.values():
        behaviours_by_go.setdefault(behaviour["game_object"], []).append(behaviour)

    world_cache: dict[int, dict] = {}
    camera_size = next(iter(cameras.values()), {"orthographic_size": 5.0})["orthographic_size"]
    viewport = [1280, 720]
    pixels_per_unit = viewport[1] / (camera_size * 2.0)

    objects = []
    for go_id, go in game_objects.items():
        transform_id = transform_by_go.get(go_id)
        if transform_id is None:
            continue
        world = combine_transform(transform_id, transforms, world_cache)
        local = transforms[transform_id]
        screen = [
            viewport[0] * 0.5 + world["position"][0] * pixels_per_unit,
            viewport[1] * 0.5 - world["position"][1] * pixels_per_unit,
        ]
        renderer = renderer_by_go.get(go_id)
        sprite = None
        if renderer:
            catalog = sprite_catalog.get(renderer["sprite_guid"], {})
            asset = catalog.get("asset", guid_map.get(renderer["sprite_guid"], ""))
            file_id = renderer["sprite_file_id"]
            sprite_entry = catalog.get("sprites", {}).get(file_id)
            if sprite_entry is None and catalog.get("image_size"):
                sprite_entry = {
                    "name": Path(asset).stem,
                    "rect_unity": [0, 0, catalog["image_size"][0], catalog["image_size"][1]],
                    "rect_godot": [0, 0, catalog["image_size"][0], catalog["image_size"][1]],
                    "pivot": [0.5, 0.5],
                }
            sprite = {
                "guid": renderer["sprite_guid"],
                "file_id": file_id,
                "asset": asset,
                "godot_path": godot_res_path(asset) if asset else "",
                "pixels_per_unit": catalog.get("pixels_per_unit", 100.0),
                "image_size": catalog.get("image_size"),
                "entry": sprite_entry,
                "color": renderer["color"],
                "sorting_order": renderer["sorting_order"],
                "size": renderer["size"],
            }

        objects.append(
            {
                "id": go_id,
                "transform_id": transform_id,
                "name": go["name"],
                "active": go["active"],
                "parent_transform": local["father"],
                "children_transforms": local["children"],
                "local": {
                    "position": local["position"],
                    "scale": local["scale"],
                    "rotation": local["rotation"],
                },
                "world": world,
                "screen": screen,
                "sprite": sprite,
                "behaviours": behaviours_by_go.get(go_id, []),
            }
        )

    objects.sort(key=lambda item: (item["sprite"]["sorting_order"] if item["sprite"] else 999, item["id"]))
    output = {
        "source": str(UNITY_SCENE),
        "viewport": viewport,
        "camera_orthographic_size": camera_size,
        "pixels_per_unit": pixels_per_unit,
        "objects": objects,
    }
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(output, indent=2, ensure_ascii=False), encoding="utf-8")

    wanted = {"Title", "Buttons", "NewGame", "QUIT", "select", "planes", "Background_02", "Stars", "Spaceship_Protagonist - P1", "friendplane", "friendplane2"}
    for item in objects:
        if item["name"] in wanted:
            print(
                f"{item['name']}: world={item['world']['position']} screen={[round(v, 2) for v in item['screen']]} "
                f"scale={item['world']['scale']} active={item['active']}"
            )
            if item["sprite"]:
                print(f"  sprite={item['sprite']['godot_path']} rect={item['sprite']['entry'] and item['sprite']['entry']['rect_godot']}")
            if item["behaviours"]:
                print(f"  behaviours={[b['values'] for b in item['behaviours']]}")
    print(f"Wrote {OUT_PATH}")


if __name__ == "__main__":
    main()
