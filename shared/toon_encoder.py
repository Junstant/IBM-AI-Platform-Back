"""
TOON (Tabular Object-Oriented Notation) Encoder/Decoder
Token-efficient format for LLM communication
"""

import json
from typing import Any, Dict, List, Union
from datetime import datetime, date
from decimal import Decimal


def encode(data: Union[Dict, List], delimiter: str = ",", length_marker: bool = False) -> str:
    """
    Encode Python dict/list to TOON format (token-efficient).
    
    Args:
        data: Dictionary or list to encode
        delimiter: Field separator (default: comma)
        length_marker: Add [#N] length markers
    
    Returns:
        TOON-formatted string
    """
    if isinstance(data, dict):
        return _encode_dict(data, delimiter, length_marker)
    elif isinstance(data, list):
        return _encode_list(data, delimiter, length_marker)
    else:
        raise ValueError("Data must be dict or list")


def _encode_dict(data: Dict[str, Any], delimiter: str, length_marker: bool) -> str:
    """Encode dictionary to TOON format."""
    lines = []
    
    for key, value in data.items():
        if isinstance(value, list) and value and isinstance(value[0], dict):
            # List of dicts -> TOON tabular format
            lines.append(_encode_tabular(key, value, delimiter, length_marker))
        elif isinstance(value, list):
            # Simple list
            length_prefix = f"[#{len(value)}]" if length_marker else ""
            items_str = delimiter.join(_serialize_value(item) for item in value)
            lines.append(f"{key}{length_prefix}: {items_str}")
        else:
            # Simple key-value
            lines.append(f"{key}: {_serialize_value(value)}")
    
    return "\n".join(lines)


def _encode_list(data: List[Dict], delimiter: str, length_marker: bool) -> str:
    """Encode list of dicts to TOON format."""
    if not data:
        return "[]"
    
    if isinstance(data[0], dict):
        return _encode_tabular("items", data, delimiter, length_marker)
    else:
        # Simple list
        length_prefix = f"[#{len(data)}]" if length_marker else ""
        items_str = delimiter.join(_serialize_value(item) for item in data)
        return f"{length_prefix}{items_str}"


def _encode_tabular(key: str, items: List[Dict], delimiter: str, length_marker: bool) -> str:
    """
    Encode list of dicts as TOON tabular format:
    
    key[N]{field1,field2}:
    value1,value2
    value3,value4
    """
    if not items:
        return f"{key}[0]:"
    
    # Get field names from first item
    fields = list(items[0].keys())
    
    # Header
    length_suffix = f"[#{len(items)}]" if length_marker else f"[{len(items)}]"
    header = f"{key}{length_suffix}{{{delimiter.join(fields)}}}:"
    
    # Data rows
    rows = []
    for item in items:
        row_values = [_serialize_value(item.get(field, "")) for field in fields]
        rows.append(delimiter.join(row_values))
    
    return f"{header}\n" + "\n".join(rows)


def _serialize_value(value: Any) -> str:
    """
    ✅ FIXED: Serialize any Python value to string (handles Decimal, datetime, etc.)
    """
    if value is None:
        return ""
    elif isinstance(value, bool):
        return "true" if value else "false"
    elif isinstance(value, (int, float)):
        return str(value)
    elif isinstance(value, Decimal):
        # ✅ FIX: Convert Decimal to float string
        return str(float(value))
    elif isinstance(value, datetime):
        return value.isoformat()
    elif isinstance(value, date):
        return value.isoformat()
    elif isinstance(value, str):
        # Escape delimiter if present
        return value.replace(",", "\\,")
    elif isinstance(value, (list, dict)):
        # Nested structures as JSON
        return json.dumps(value, default=_json_serializer)
    else:
        return str(value)


def _json_serializer(obj: Any) -> str:
    """
    ✅ FIXED: Custom JSON serializer for non-standard types
    """
    if isinstance(obj, Decimal):
        return float(obj)
    elif isinstance(obj, (datetime, date)):
        return obj.isoformat()
    else:
        return str(obj)


def decode(toon_str: str) -> Union[Dict, List]:
    """
    Decode TOON format back to Python dict/list.
    
    Args:
        toon_str: TOON-formatted string
    
    Returns:
        Python dict or list
    """
    lines = [line.strip() for line in toon_str.strip().split("\n") if line.strip()]
    
    if not lines:
        return {}
    
    result = {}
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Check if tabular format
        if "[" in line and "{" in line and ":" in line:
            key, table_data = _decode_tabular(line, lines[i+1:])
            result[key] = table_data
            
            # Skip processed lines
            i += len(table_data) + 1
        else:
            # Simple key-value
            if ":" in line:
                key, value = line.split(":", 1)
                result[key.strip()] = value.strip()
            i += 1
    
    return result


def _decode_tabular(header_line: str, data_lines: List[str]) -> tuple:
    """Decode TOON tabular format back to list of dicts."""
    # Parse header: key[N]{field1,field2}:
    key = header_line.split("[")[0].strip()
    fields_part = header_line.split("{")[1].split("}")[0]
    fields = [f.strip() for f in fields_part.split(",")]
    
    # Parse data rows
    items = []
    for line in data_lines:
        if not line or line.startswith("[") or "{" in line:
            break
        
        values = [v.strip() for v in line.split(",")]
        
        if len(values) == len(fields):
            item = {}
            for field, value in zip(fields, values):
                item[field] = _deserialize_value(value)
            items.append(item)
    
    return key, items


def _deserialize_value(value: str) -> Any:
    """Convert string back to appropriate Python type."""
    if value == "":
        return None
    elif value == "true":
        return True
    elif value == "false":
        return False
    elif value.replace(".", "").replace("-", "").isdigit():
        # Try to parse as number
        try:
            if "." in value:
                return float(value)
            else:
                return int(value)
        except ValueError:
            return value
    else:
        return value


def estimate_token_savings(data: Union[Dict, List]) -> Dict[str, Any]:
    """
    Estimate token savings using TOON vs JSON.
    
    Returns:
        Dict with statistics (json_length, toon_length, savings_percent)
    """
    # Convert to JSON
    json_str = json.dumps(data, indent=2, default=_json_serializer)
    json_length = len(json_str)
    
    # Convert to TOON
    toon_str = encode(data)
    toon_length = len(toon_str)
    
    # Calculate savings
    savings = json_length - toon_length
    savings_percent = (savings / json_length * 100) if json_length > 0 else 0
    
    # Estimate tokens (rough approximation: 1 token ≈ 4 chars)
    json_tokens = json_length // 4
    toon_tokens = toon_length // 4
    token_savings = json_tokens - toon_tokens
    
    return {
        "json_chars": json_length,
        "toon_chars": toon_length,
        "savings_chars": savings,
        "savings_percent": round(savings_percent, 2),
        "json_tokens_approx": json_tokens,
        "toon_tokens_approx": toon_tokens,
        "token_savings_approx": token_savings
    }
