#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from dataclasses import dataclass
from typing import Callable, Dict, Iterable, Iterator, List, Optional, Set, Tuple
import shutil


DEFAULT_FILE_EXTENSIONS = {".h", ".m", ".mm"}
IMPLEMENTATION_EXTENSIONS = {".m", ".mm"}
IMPORT_PATTERN = re.compile(r"#import\s+([\"<])([^\"<>\n]+)([\">])")
INCLUDE_PATTERN = re.compile(r"#include\s+([\"<])([^\"<>\n]+)([\">])")
OLD_OBFUSCATED_NAME_PATTERN = re.compile(r"^OC[0-9A-F]{10}$")
METHOD_PATTERN = re.compile(r"^[+-]\s*\([^)]*\)\s*(.*?)(?=[{;])", re.MULTILINE | re.DOTALL)
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
DEFAULT_SOURCE_ROOT = (REPO_ROOT / "src").resolve()
DEFAULT_CLASS_MAPPING_PATH = (SCRIPT_DIR / "mappings" / "nsftrproj_classes.json").resolve()
DEFAULT_METHOD_MAPPING_PATH = (SCRIPT_DIR / "mappings" / "nsftrproj_methods.json").resolve()
DEFAULT_PROPERTY_MAPPING_PATH = (SCRIPT_DIR / "mappings" / "nsftrproj_properties.json").resolve()
DEFAULT_BACKUP_ROOT = (REPO_ROOT / "src_backup_before_obfuscation").resolve()
DEFAULT_DISCOVERY_PATHS = [
    "App",
    "HUD",
    "Menu",
    "UI",
]
DEFAULT_EXCLUDE_DIRS = [
    "Cheat",
    "Helpers",
    "Helpers/private_headers",
]
DEFAULT_EXCLUDE_CLASSES = [
    "PSAppDataUsagePolicyCache",
    "ToggleSwitch",
    "SegmentedControl",
    "Slider",
]
DEFAULT_EXCLUDE_SELECTORS = {
    "load",
    "layoutSubviews",
    "preferredStatusBarStyle",
    "preferredInterfaceOrientationForPresentation",
    "supportedInterfaceOrientations",
    "shouldAutorotate",
    "viewWillLayoutSubviews",
    "updateViewConstraints",
    "traitCollectionDidChange:",
    "becomeFirstResponder",
    "resignFirstResponder",
    "canBecomeFirstResponder",
    "canPerformAction:withSender:",
    "targetForAction:withSender:",
    "applicationDidBecomeActive:",
    "applicationWillResignActive:",
    "applicationWillEnterForeground:",
    "applicationDidEnterBackground:",
    "applicationWillTerminate:",
    "scene:willConnectToSession:options:",
    "sceneDidBecomeActive:",
    "sceneWillResignActive:",
    "sceneWillEnterForeground:",
    "sceneDidEnterBackground:",
    "prepareForSegue:sender:",
    "shouldPerformSegueWithIdentifier:sender:",
    "addTarget:action:",
    "stringForKey:",
    "integerForKey:",
    "floatForKey:",
    "setObject:forKey:",
    "setInteger:forKey:",
    "setFloat:forKey:",
    "setDouble:forKey:",
    "setValue:",
    "setOn:animated:",
    "compare:",
    "viewDidLoad",
    "viewDidLayoutSubviews",
    "viewDidAppear:",
    "viewWillAppear:",
    "viewWillDisappear:",
    "viewDidDisappear:",
    "viewSafeAreaInsetsDidChange",
    "application:didFinishLaunchingWithOptions:",
    "animationDidStop:finished:",
    "gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:",
    "drawInMTKView:",
    "mtkView:drawableSizeWillChange:",
}
DEFAULT_EXCLUDE_SELECTOR_PREFIXES = (
    "init",
    "dealloc",
    "viewDid",
    "viewWill",
    "touches",
    "application",
    "scene",
    "tableView",
    "collectionView",
    "scrollView",
    "navigationController",
    "animation",
    "webView",
    "numberOf",
    "_",
)
RESERVED_SELECTOR_SEGMENTS = {
    "action",
    "animateWithDuration",
    "animations",
    "animated",
    "completion",
    "completionHandler",
    "forKey",
    "inWindow",
    "handler",
    "message",
    "onView",
    "name",
    "object",
    "options",
    "error",
    "isEqual",
    "preferredStyle",
    "selector",
    "target",
    "userInfo",
}

PROPERTY_SKIP_NAMES = {
    "bounds",
    "center",
    "contentview",
    "count",
    "description",
    "device",
    "frame",
    "height",
    "length",
    "label",
    "message",
    "name",
    "options",
    "origin",
    "placeholder",
    "pixelformat",
    "colorpixelformat",
    "depthpixelformat",
    "stencilpixelformat",
    "samplecount",
    "size",
    "target",
    "title",
    "type",
    "userinfo",
    "value",
    "width",
    "window",
    "x",
    "y",
    "selectedindex",
}

MALAYALAM_ALPHABET: Tuple[str, ...] = (
    "അ",
    "ആ",
    "ഇ",
    "ഈ",
    "ഉ",
    "ഊ",
    "ഋ",
    "എ",
    "ഏ",
    "ഐ",
    "ഒ",
    "ഓ",
    "ഔ",
    "ക",
    "ഖ",
    "ഗ",
    "ഘ",
    "ങ",
    "ച",
    "ഛ",
    "ജ",
    "ഝ",
    "ഞ",
    "ട",
    "ഠ",
    "ഡ",
    "ഢ",
    "ണ",
    "ത",
    "ഥ",
    "ദ",
    "ധ",
)
MALAYALAM_ALPHABET_SET: Set[str] = set(MALAYALAM_ALPHABET)
MALAYALAM_CHAR_CLASS = "".join(re.escape(ch) for ch in MALAYALAM_ALPHABET)
MALAYALAM_BASE = len(MALAYALAM_ALPHABET)
CLASS_NAME_PREFIX = MALAYALAM_ALPHABET[0]
PROPERTY_NAME_PREFIX = MALAYALAM_ALPHABET[1]
METHOD_NAME_PREFIX = MALAYALAM_ALPHABET[2]
CLASS_NAME_TOTAL_LENGTH = 12
CLASS_NAME_BODY_LENGTH = CLASS_NAME_TOTAL_LENGTH - 1
PROPERTY_NAME_TOTAL_LENGTH = 12
PROPERTY_NAME_BODY_LENGTH = PROPERTY_NAME_TOTAL_LENGTH - 1
METHOD_NAME_SEGMENT_LENGTH = 12
METHOD_NAME_SEGMENT_BODY_LENGTH = METHOD_NAME_SEGMENT_LENGTH - 1
NEW_OBFUSCATED_NAME_PATTERN = re.compile(
    rf"^{re.escape(CLASS_NAME_PREFIX)}[{MALAYALAM_CHAR_CLASS}]{{{CLASS_NAME_BODY_LENGTH}}}$"
)
IDENTIFIER_RE = r"[^\W\d_][\w]*"


def resolve_discovery_paths(source_root: Path, entries: Iterable[str]) -> List[Path]:
    if not entries:
        return [source_root.resolve()]

    resolved: List[Path] = []
    seen: Set[Path] = set()
    for entry in entries:
        candidate = Path(entry)
        if not candidate.is_absolute():
            candidate = (source_root / candidate).resolve()
        else:
            candidate = candidate.resolve()
        if not candidate.exists():
            continue
        if candidate in seen:
            continue
        seen.add(candidate)
        resolved.append(candidate)

    if not resolved:
        return [source_root.resolve()]
    return resolved


def resolve_exclude_paths(source_root: Path, entries: Iterable[str]) -> Set[Path]:
    resolved: Set[Path] = set()
    for entry in entries:
        candidate = Path(entry)
        if not candidate.is_absolute():
            candidate = (source_root / candidate).resolve()
        else:
            candidate = candidate.resolve()
        if candidate.exists():
            resolved.add(candidate)
    return resolved


def is_within_path(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def iter_discovery_files(
    allowed_paths: Iterable[Path],
    extensions: Set[str],
    exclude_paths: Set[Path],
) -> Iterator[Path]:
    seen: Set[Path] = set()
    for base_path in allowed_paths:
        if not base_path.exists():
            continue

        if base_path.is_file():
            if base_path.suffix in extensions:
                canonical = base_path.resolve()
                if any(is_within_path(canonical, excluded) for excluded in exclude_paths):
                    continue
                if canonical not in seen:
                    seen.add(canonical)
                    yield base_path
            continue

        for file_path in base_path.rglob("*"):
            if not file_path.is_file():
                continue
            if file_path.suffix not in extensions:
                continue
            canonical = file_path.resolve()
            if canonical in seen:
                continue
            if any(is_within_path(canonical, excluded) for excluded in exclude_paths):
                continue
            seen.add(canonical)
            yield file_path


@dataclass(frozen=True)
class PropertyDescriptor:
    name: str
    getter: str
    setter: Optional[str]


def encode_malayalam_identifier(seed: str, length: int) -> str:
    digest = hashlib.sha256(seed.encode("utf-8")).digest()
    value = int.from_bytes(digest, "big")
    chars: List[str] = []
    for _ in range(length):
        value, remainder = divmod(value, MALAYALAM_BASE)
        chars.append(MALAYALAM_ALPHABET[remainder])
    return "".join(reversed(chars))


def restore_source_tree_from_backup(source_root: Path, backup_root: Path) -> None:
    if not backup_root.exists():
        return

    if not source_root.exists():
        source_root.mkdir(parents=True, exist_ok=True)

    for backup_path in backup_root.rglob("*"):
        relative_path = backup_path.relative_to(backup_root)
        target_path = source_root / relative_path
        if backup_path.is_dir():
            target_path.mkdir(parents=True, exist_ok=True)
            continue

        target_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(backup_path, target_path)


def capitalize_first(name: str) -> str:
    if not name:
        return name
    return name[0].upper() + name[1:]


def default_setter_name(property_name: str) -> str:
    if not property_name:
        return "set:"
    if property_name.startswith("is") and len(property_name) > 2 and property_name[2].isupper():
        base = property_name[2:]
    else:
        base = capitalize_first(property_name)
    return f"set{base}:"


def parse_property_attributes(
    attribute_group: Optional[str],
    property_name: str,
) -> Tuple[str, Optional[str]]:
    getter = property_name
    setter: Optional[str] = default_setter_name(property_name)
    if not attribute_group:
        return getter, setter

    content = attribute_group.strip()[1:-1] if attribute_group else ""
    for raw_part in content.split(","):
        part = raw_part.strip()
        if not part:
            continue
        if part == "readonly":
            setter = None
            continue
        if part.startswith("getter="):
            getter = part.split("=", 1)[1].strip()
            continue
        if part.startswith("setter="):
            setter_value = part.split("=", 1)[1].strip()
            if setter_value and not setter_value.endswith(":"):
                setter_value = setter_value + ":"
            setter = setter_value or None
    return getter, setter


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Apply deterministic Objective-C/Objective-C++ symbol obfuscation."
    )
    parser.add_argument(
        "--source-root",
        type=Path,
        default=DEFAULT_SOURCE_ROOT,
        help=f"Root directory containing source files to obfuscate (default: {DEFAULT_SOURCE_ROOT}).",
    )
    parser.add_argument(
        "--mapping",
        type=Path,
        default=DEFAULT_CLASS_MAPPING_PATH,
        help=f"Path to JSON file storing class obfuscation mapping (default: {DEFAULT_CLASS_MAPPING_PATH}).",
    )
    parser.add_argument(
        "--method-mapping",
        type=Path,
        default=DEFAULT_METHOD_MAPPING_PATH,
        help=f"Path to JSON file storing method obfuscation mapping (default: {DEFAULT_METHOD_MAPPING_PATH}).",
    )
    parser.add_argument(
        "--property-mapping",
        type=Path,
        default=DEFAULT_PROPERTY_MAPPING_PATH,
        help=(
            "Path to JSON file storing property obfuscation mapping "
            f"(default: {DEFAULT_PROPERTY_MAPPING_PATH})."
        ),
    )
    parser.add_argument(
        "--exclude-dir",
        action="append",
        default=None,
        help="Relative directory (from source root) to exclude. Can be passed multiple times.",
    )
    parser.add_argument(
        "--allow-path",
        action="append",
        default=None,
        help=(
            "Relative file or directory (from source root) to include during symbol discovery. "
            "Can be passed multiple times."
        ),
    )
    parser.add_argument(
        "--extensions",
        nargs="*",
        default=sorted(DEFAULT_FILE_EXTENSIONS),
        help="File extensions to process (defaults to .h .m .mm).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Compute mappings but do not mutate files.",
    )
    parser.add_argument(
        "--exclude-class",
        action="append",
        default=None,
        help="Specific Objective-C class names to leave untouched.",
    )
    parser.add_argument(
        "--exclude-selector",
        action="append",
        default=None,
        help="Specific method selectors to leave untouched.",
    )
    parser.add_argument(
        "--exclude-selector-prefix",
        action="append",
        default=None,
        help="Method selector prefixes to leave untouched.",
    )

    args = parser.parse_args()

    if args.allow_path is None:
        args.allow_path = list(DEFAULT_DISCOVERY_PATHS)
    if args.exclude_dir is None:
        args.exclude_dir = list(DEFAULT_EXCLUDE_DIRS)
    if args.exclude_class is None:
        args.exclude_class = list(DEFAULT_EXCLUDE_CLASSES)

    selector_exclusions: Set[str] = set(DEFAULT_EXCLUDE_SELECTORS)
    if args.exclude_selector:
        selector_exclusions.update(args.exclude_selector)
    args.exclude_selector = selector_exclusions

    prefix_exclusions: List[str] = list(DEFAULT_EXCLUDE_SELECTOR_PREFIXES)
    if args.exclude_selector_prefix:
        prefix_exclusions.extend(args.exclude_selector_prefix)
    args.exclude_selector_prefix = tuple(prefix_exclusions)

    return args


def discover_class_names(
    source_root: Path,
    extensions: Iterable[str],
    allowed_paths: Iterable[Path],
    exclude_paths: Set[Path],
) -> Set[str]:
    class_names: Set[str] = set()
    extensions = {ext if ext.startswith(".") else f".{ext}" for ext in extensions}

    resolved_allowed = [path.resolve() for path in allowed_paths]
    resolved_exclude = {path.resolve() for path in exclude_paths}

    interface_pattern = re.compile(rf"@interface\s+({IDENTIFIER_RE})", re.UNICODE)
    implementation_pattern = re.compile(rf"@implementation\s+({IDENTIFIER_RE})", re.UNICODE)

    for file_path in iter_discovery_files(resolved_allowed, extensions, resolved_exclude):
        try:
            text = file_path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        for pattern in (interface_pattern, implementation_pattern):
            for match in pattern.finditer(text):
                index = match.end()
                while index < len(text) and text[index].isspace():
                    index += 1
                if index < len(text) and text[index] == "(":
                    continue
                class_names.add(match.group(1))

    return {name for name in class_names if not is_generated_name(name)}


def generate_deterministic_name(original: str, used: Set[str]) -> str:
    seed = original
    while True:
        candidate = CLASS_NAME_PREFIX + encode_malayalam_identifier(seed, CLASS_NAME_BODY_LENGTH)
        if candidate not in used:
            used.add(candidate)
            return candidate
        seed += "_"


def is_generated_name(name: str) -> bool:
    return bool(
        OLD_OBFUSCATED_NAME_PATTERN.fullmatch(name)
        or NEW_OBFUSCATED_NAME_PATTERN.fullmatch(name)
    )


def generate_property_name(obfuscated_class_name: str, property_name: str, used: Set[str]) -> str:
    seed = f"{obfuscated_class_name}:{property_name}"
    counter = 0
    while True:
        candidate = PROPERTY_NAME_PREFIX + encode_malayalam_identifier(
            f"{seed}:{counter}", PROPERTY_NAME_BODY_LENGTH
        )
        if candidate not in used:
            used.add(candidate)
            return candidate
        counter += 1


def collect_class_properties(
    source_root: Path,
    class_mapping: Dict[str, str],
    extensions: Iterable[str],
    allowed_paths: Iterable[Path],
    exclude_paths: Set[Path],
) -> Dict[str, Dict[str, PropertyDescriptor]]:
    properties: Dict[str, Dict[str, PropertyDescriptor]] = {}
    extensions = {ext if ext.startswith(".") else f".{ext}" for ext in extensions}
    obf_to_original = {obfuscated: original for original, obfuscated in class_mapping.items()}
    original_names = set(class_mapping.keys())

    resolved_allowed = [path.resolve() for path in allowed_paths]
    resolved_exclude = {path.resolve() for path in exclude_paths}

    interface_pattern = re.compile(rf"@interface\s+({IDENTIFIER_RE})(?:\s*\([^)]*\))?", re.UNICODE)
    property_pattern = re.compile(
        rf"@property\s*(\([^\)]*\))?\s*[^;]*?\b({IDENTIFIER_RE})\s*;",
        re.UNICODE,
    )

    for file_path in iter_discovery_files(resolved_allowed, extensions, resolved_exclude):
        try:
            text = file_path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        for match in interface_pattern.finditer(text):
            class_name = match.group(1)
            original_name = obf_to_original.get(class_name)
            if not original_name and class_name in original_names:
                original_name = class_name
            if not original_name:
                continue
            start = match.end()
            end = text.find("@end", start)
            if end == -1:
                continue
            block = text[start:end]
            for prop_match in property_pattern.finditer(block):
                attributes = prop_match.group(1)
                prop_name = prop_match.group(2)
                if prop_name.lower() in PROPERTY_SKIP_NAMES:
                    continue
                getter, setter = parse_property_attributes(attributes, prop_name)
                class_props = properties.setdefault(original_name, {})
                class_props[prop_name] = PropertyDescriptor(
                    name=prop_name,
                    getter=getter,
                    setter=setter,
                )

    return properties


def selector_is_property_related(
    selector: str,
    properties: Dict[str, PropertyDescriptor],
) -> bool:
    for descriptor in properties.values():
        if selector == descriptor.name or selector == descriptor.getter:
            return True
        if descriptor.setter and selector == descriptor.setter:
            return True
    return False


def should_skip_selector(
    selector: str,
    properties: Dict[str, PropertyDescriptor],
    exclude_selectors: Set[str],
    exclude_prefixes: Tuple[str, ...],
) -> bool:
    if selector in exclude_selectors:
        return True

    first_segment = selector.split(":")[0]
    for prefix in exclude_prefixes:
        if first_segment.startswith(prefix):
            return True

    if properties and selector_is_property_related(selector, properties):
        return True

    if ":" in selector:
        segments = [segment for segment in selector.split(":") if segment]
        if segments and all(segment in RESERVED_SELECTOR_SEGMENTS for segment in segments):
            return True
    return False


def parse_selector(signature_part: str) -> Optional[str]:
    colon_parts = re.findall(rf"({IDENTIFIER_RE}:)", signature_part, re.UNICODE)
    if colon_parts:
        return "".join(colon_parts)

    match = re.match(rf"\s*({IDENTIFIER_RE})", signature_part, re.UNICODE)
    if match:
        return match.group(1)

    return None


def discover_method_selectors(
    source_root: Path,
    class_mapping: Dict[str, str],
    extensions: Iterable[str],
    allowed_paths: Iterable[Path],
    exclude_paths: Set[Path],
    property_map: Dict[str, Dict[str, PropertyDescriptor]],
    exclude_selectors: Set[str],
    exclude_prefixes: Tuple[str, ...],
) -> Dict[str, Set[str]]:
    selectors: Dict[str, Set[str]] = {}
    obf_to_original = {obfuscated: original for original, obfuscated in class_mapping.items()}
    original_names = set(class_mapping.keys())

    resolved_allowed = [path.resolve() for path in allowed_paths]
    resolved_exclude = {path.resolve() for path in exclude_paths}

    for file_path in iter_discovery_files(resolved_allowed, IMPLEMENTATION_EXTENSIONS, resolved_exclude):
        try:
            text = file_path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        for impl_match in re.finditer(rf"@implementation\s+({IDENTIFIER_RE})", text, re.UNICODE):
            obfuscated_name = impl_match.group(1)
            original_name = obf_to_original.get(obfuscated_name)
            if not original_name and obfuscated_name in original_names:
                original_name = obfuscated_name
            if not original_name:
                continue
            start = impl_match.end()
            end = text.find("@end", start)
            if end == -1:
                continue
            block = text[start:end]
            prop_descriptors = property_map.get(original_name, {})

            for method_match in METHOD_PATTERN.finditer(block):
                signature_part = method_match.group(1)
                selector = parse_selector(signature_part)
                if not selector:
                    continue
                if should_skip_selector(selector, prop_descriptors, exclude_selectors, exclude_prefixes):
                    continue
                selectors.setdefault(original_name, set()).add(selector)

    return {cls: sels for cls, sels in selectors.items() if sels}


def generate_method_selector(
    obfuscated_class_name: str,
    selector: str,
    used_values: Set[str],
) -> str:
    base = f"{obfuscated_class_name}:{selector}"
    if ":" in selector:
        segments = [segment for segment in selector.split(":") if segment]
        new_segments: List[str] = []
        for index, segment in enumerate(segments):
            if segment in RESERVED_SELECTOR_SEGMENTS:
                new_segments.append(segment + ":")
                continue
            seed = 0
            candidate: str
            while True:
                candidate = METHOD_NAME_PREFIX + encode_malayalam_identifier(
                    f"{base}:{index}:{seed}", METHOD_NAME_SEGMENT_BODY_LENGTH
                )
                if candidate not in used_values:
                    used_values.add(candidate)
                    break
                seed += 1
            new_segments.append(candidate + ":")
        return "".join(new_segments)

    seed = 0
    while True:
        candidate = METHOD_NAME_PREFIX + encode_malayalam_identifier(
            f"{base}:{seed}", METHOD_NAME_SEGMENT_BODY_LENGTH
        )
        if candidate not in used_values:
            used_values.add(candidate)
            return candidate
        seed += 1


def load_or_create_class_mapping(mapping_path: Path, class_names: Set[str]) -> Dict[str, str]:
    mapping: Dict[str, str] = {}
    if mapping_path.exists():
        data = json.loads(mapping_path.read_text(encoding="utf-8"))
        mapping = {str(k): str(v) for k, v in data.items()}

    changed = False
    for existing in list(mapping.keys()):
        if existing not in class_names:
            del mapping[existing]
            changed = True

    used_names: Set[str] = set(mapping.values())

    for class_name in sorted(class_names):
        if class_name in mapping:
            continue
        mapping[class_name] = generate_deterministic_name(class_name, used_names)
        changed = True

    if changed or not mapping_path.exists():
        mapping_path.parent.mkdir(parents=True, exist_ok=True)
        mapping_path.write_text(json.dumps(mapping, indent=2, sort_keys=True), encoding="utf-8")
    return mapping


def load_or_create_property_mapping(
    mapping_path: Path,
    class_mapping: Dict[str, str],
    property_descriptors: Dict[str, Dict[str, PropertyDescriptor]],
) -> Dict[str, Dict[str, str]]:
    mapping: Dict[str, Dict[str, str]] = {}
    if mapping_path.exists():
        data = json.loads(mapping_path.read_text(encoding="utf-8"))
        mapping = {
            str(cls): {str(prop): str(new_name) for prop, new_name in props.items()}
            for cls, props in data.items()
        }

    changed = False
    used_names: Set[str] = set()
    for props in mapping.values():
        used_names.update(props.values())

    # Remove classes without properties.
    for cls in list(mapping.keys()):
        if cls not in property_descriptors or not property_descriptors[cls]:
            del mapping[cls]
            changed = True

    # Remove properties no longer present.
    for cls, props in list(mapping.items()):
        descriptors = property_descriptors.get(cls, {})
        for prop in list(props.keys()):
            if prop not in descriptors:
                del props[prop]
                changed = True

    for cls, descriptors in property_descriptors.items():
        if not descriptors:
            continue
        obfuscated_class = class_mapping.get(cls)
        if not obfuscated_class:
            continue
        class_props = mapping.setdefault(cls, {})
        for prop_name in sorted(descriptors.keys()):
            if prop_name in class_props:
                continue
            class_props[prop_name] = generate_property_name(obfuscated_class, prop_name, used_names)
            changed = True

    if changed or not mapping_path.exists():
        mapping_path.parent.mkdir(parents=True, exist_ok=True)
        mapping_path.write_text(json.dumps(mapping, indent=2, sort_keys=True), encoding="utf-8")

    return mapping


def load_or_create_method_mapping(
    mapping_path: Path,
    class_mapping: Dict[str, str],
    selectors_by_class: Dict[str, Set[str]],
) -> Dict[str, Dict[str, str]]:
    mapping: Dict[str, Dict[str, str]] = {}
    if mapping_path.exists():
        data = json.loads(mapping_path.read_text(encoding="utf-8"))
        mapping = {
            str(cls): {str(sel): str(new_sel) for sel, new_sel in methods.items()}
            for cls, methods in data.items()
        }

    changed = False
    used_values: Set[str] = set()
    for methods in mapping.values():
        used_values.update(methods.values())

    # Remove classes no longer in scope.
    for cls in list(mapping.keys()):
        if cls not in selectors_by_class:
            del mapping[cls]
            changed = True

    # Remove selectors no longer present.
    for cls, methods in list(mapping.items()):
        valid_selectors = selectors_by_class.get(cls, set())
        for selector in list(methods.keys()):
            if selector not in valid_selectors:
                del methods[selector]
                changed = True

    for cls, selectors in selectors_by_class.items():
        methods = mapping.setdefault(cls, {})
        obfuscated_class = class_mapping.get(cls)
        if not obfuscated_class:
            continue
        for selector in sorted(selectors):
            if selector in methods:
                continue
            methods[selector] = generate_method_selector(obfuscated_class, selector, used_values)
            changed = True

    if changed or not mapping_path.exists():
        mapping_path.parent.mkdir(parents=True, exist_ok=True)
        mapping_path.write_text(json.dumps(mapping, indent=2, sort_keys=True), encoding="utf-8")
    return mapping


def restore_include_paths(text: str, class_mapping: Dict[str, str]) -> str:
    def restore(path: str) -> str:
        parts = path.split("/")
        if not parts:
            return path

        for index, part in enumerate(parts):
            if "." in part:
                stem, dot, ext = part.partition(".")
                suffix = dot + ext
            else:
                stem, suffix = part, ""

            for original, obfuscated in class_mapping.items():
                if stem == obfuscated:
                    parts[index] = original + suffix
                    break

        return "/".join(parts)

    def import_repl(match: re.Match[str]) -> str:
        opener, path, closer = match.groups()
        return f"#import {opener}{restore(path)}{closer}"

    def include_repl(match: re.Match[str]) -> str:
        opener, path, closer = match.groups()
        return f"#include {opener}{restore(path)}{closer}"

    text = IMPORT_PATTERN.sub(import_repl, text)
    text = INCLUDE_PATTERN.sub(include_repl, text)
    return text


def build_class_patterns(class_mapping: Dict[str, str]) -> List[Tuple[re.Pattern[str], str]]:
    patterns: List[Tuple[re.Pattern[str], str]] = []
    for original, obfuscated in class_mapping.items():
        pattern = re.compile(rf"\b{re.escape(original)}\b")
        patterns.append((pattern, obfuscated))
    return patterns


def build_method_patterns(method_mapping: Dict[str, Dict[str, str]]) -> List[Tuple[re.Pattern[str], str]]:
    patterns: List[Tuple[re.Pattern[str], str]] = []
    for methods in method_mapping.values():
        for selector, obfuscated in methods.items():
            if ":" in selector:
                old_segments = [seg for seg in selector.split(":") if seg]
                new_segments = [seg for seg in obfuscated.split(":") if seg]
                if len(old_segments) != len(new_segments):
                    continue
                for old, new in zip(old_segments, new_segments):
                    if old == new:
                        continue
                    pattern = re.compile(rf"(?<!\w){re.escape(old)}(?=\s*:)", re.UNICODE)
                    patterns.append((pattern, new))
            else:
                if selector == obfuscated:
                    continue
                pattern = re.compile(
                    rf"(?<!\w){re.escape(selector)}(?!\w|\s*\()",
                    re.UNICODE,
                )
                patterns.append((pattern, obfuscated))
    return patterns


def build_property_patterns(
    property_mapping: Dict[str, Dict[str, str]],
    property_descriptors: Dict[str, Dict[str, PropertyDescriptor]],
) -> List[Tuple[re.Pattern[str], Callable[[re.Match[str]], str] | str]]:
    patterns: List[Tuple[re.Pattern[str], Callable[[re.Match[str]], str] | str]] = []

    for cls, props in property_mapping.items():
        descriptors = property_descriptors.get(cls, {})
        for prop_name, obfuscated in props.items():
            descriptor = descriptors.get(prop_name)
            if not descriptor:
                continue

            # @property declarations
            patterns.append(
                (
                    re.compile(
                        rf"(@property\s*(?:\([^)]+\))?\s*[^;]*\b){re.escape(prop_name)}(\b)"
                    ),
                    (lambda repl: lambda m: m.group(1) + repl + m.group(2))(obfuscated),
                )
            )

            # Dot syntax and pointer access
            patterns.append(
                (
                    re.compile(rf"(?<=\.){re.escape(prop_name)}\b(?!\s*\()"),
                    obfuscated,
                )
            )
            # Rename ivar access via self->prop
            patterns.append(
                (
                    re.compile(rf"(self->){re.escape(prop_name)}\b"),
                    (lambda repl: lambda m: m.group(1) + repl)(obfuscated),
                )
            )
            # Revert accidental struct-field obfuscation (non-self arrow access)
            patterns.append(
                (
                    re.compile(rf"({IDENTIFIER_RE})->{re.escape(obfuscated)}\b", re.UNICODE),
                    (lambda original: lambda m: m.group(0) if m.group(1) == "self" else f"{m.group(1)}->{original}")(prop_name),
                )
            )

            # Backing ivar usage
            patterns.append((re.compile(rf"\b_{re.escape(prop_name)}\b"), f"_{obfuscated}"))

            # @synthesize / @dynamic
            patterns.append(
                (
                    re.compile(rf"(@synthesize\s+){re.escape(prop_name)}\b"),
                    (lambda repl: lambda m: m.group(1) + repl)(obfuscated),
                )
            )
            patterns.append(
                (
                    re.compile(rf"(@dynamic\s+){re.escape(prop_name)}\b"),
                    (lambda repl: lambda m: m.group(1) + repl)(obfuscated),
                )
            )

            # Getter-specific updates when getter matches property name.
            if descriptor.getter == prop_name:
                patterns.append(
                    (
                        re.compile(rf"(@selector\s*\(\s*){re.escape(prop_name)}(\s*\))"),
                        (lambda repl: lambda m: m.group(1) + repl + m.group(2))(obfuscated),
                    )
                )
                patterns.append(
                    (
                        re.compile(
                            r"([+-]\s*\([^)]*\)\s*)%s(?=\s*(?:[{;]))" % re.escape(prop_name)
                        ),
                        (lambda repl: lambda m: m.group(1) + repl)(obfuscated),
                    )
                )

            # Setter-specific updates when a setter exists.
            if descriptor.setter:
                setter_base = descriptor.setter[:-1]
                new_setter = default_setter_name(obfuscated)
                new_setter_base = new_setter[:-1]
                patterns.append(
                    (
                        re.compile(rf"(@selector\s*\(\s*){re.escape(setter_base)}\s*:"),
                        (lambda repl: lambda m: m.group(1) + repl + ":")(new_setter_base),
                    )
                )
                patterns.append(
                    (
                        re.compile(rf"([+-]\s*\([^)]*\)\s*){re.escape(setter_base)}(?=\s*:)"),
                        (lambda repl: lambda m: m.group(1) + repl)(new_setter_base),
                    )
                )
                patterns.append(
                    (
                        re.compile(rf"(\[self\s+){re.escape(setter_base)}(?=\s*:)"),
                        (lambda repl: lambda m: m.group(1) + repl)(new_setter_base),
                    )
                )

    return patterns


def apply_mapping(
    source_root: Path,
    class_mapping: Dict[str, str],
    method_mapping: Dict[str, Dict[str, str]],
    property_mapping: Dict[str, Dict[str, str]],
    property_descriptors: Dict[str, Dict[str, PropertyDescriptor]],
    extensions: Iterable[str],
) -> List[Path]:
    modified_files: List[Path] = []
    extensions = {ext if ext.startswith(".") else f".{ext}" for ext in extensions}
    class_patterns = build_class_patterns(class_mapping)
    property_patterns = build_property_patterns(property_mapping, property_descriptors)
    method_patterns = build_method_patterns(method_mapping)
    all_patterns = class_patterns + property_patterns + method_patterns

    if not all_patterns:
        return modified_files

    for file_path in source_root.rglob("*"):
        if not file_path.is_file():
            continue
        if file_path.suffix not in extensions:
            continue

        try:
            text = file_path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        updated = text
        for pattern, replacement in all_patterns:
            updated = pattern.sub(replacement, updated)

        if updated != text:
            updated = restore_include_paths(updated, class_mapping)

        if updated != text:
            file_path.write_text(updated, encoding="utf-8")
            modified_files.append(file_path)

    return modified_files


def main() -> int:
    args = parse_args()
    source_root = args.source_root.resolve()
    restore_source_tree_from_backup(source_root, DEFAULT_BACKUP_ROOT)
    if not source_root.exists():
        print(f"Source root '{source_root}' does not exist.", file=sys.stderr)
        return 1

    allowed_paths = resolve_discovery_paths(source_root, args.allow_path)
    exclude_paths = resolve_exclude_paths(source_root, args.exclude_dir)

    class_names = discover_class_names(source_root, args.extensions, allowed_paths, exclude_paths)
    if args.exclude_class:
        class_names.difference_update(args.exclude_class)

    class_mapping = load_or_create_class_mapping(args.mapping, class_names)

    property_map = collect_class_properties(
        source_root,
        class_mapping,
        args.extensions,
        allowed_paths,
        exclude_paths,
    )
    property_mapping = load_or_create_property_mapping(
        args.property_mapping,
        class_mapping,
        property_map,
    )
    method_selectors = discover_method_selectors(
        source_root,
        class_mapping,
        args.extensions,
        allowed_paths,
        exclude_paths,
        property_map,
        args.exclude_selector,
        args.exclude_selector_prefix,
    )
    method_mapping = load_or_create_method_mapping(args.method_mapping, class_mapping, method_selectors)

    discovered_methods = sum(len(selectors) for selectors in method_selectors.values())

    if args.dry_run:
        print(
            f"Discovered {len(class_names)} classes and {discovered_methods} obfuscatable methods."
        )
        print(f"Class mapping persisted to {args.mapping}.")
        if method_selectors:
            print(f"Method mapping persisted to {args.method_mapping}.")
        if property_map:
            print(f"Property mapping persisted to {args.property_mapping}.")
        return 0

    modified_files = apply_mapping(
        source_root,
        class_mapping,
        method_mapping,
        property_mapping,
        property_map,
        args.extensions,
    )

    if class_names:
        print(f"Obfuscated {len(class_mapping)} classes using stored mapping.")
    if method_mapping:
        total_methods = sum(len(methods) for methods in method_mapping.values())
        print(f"Obfuscated {total_methods} methods across {len(method_mapping)} classes.")
    if property_mapping:
        total_properties = sum(len(props) for props in property_mapping.values())
        print(f"Obfuscated {total_properties} properties across {len(property_mapping)} classes.")
    print(f"Modified {len(modified_files)} files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
