"""
TOON (Tabular Object-Oriented Notation) - Token-efficient format for LLMs
Optimiza el uso de tokens eliminando redundancias de JSON
"""

import json
from typing import Any, Dict, List, Union
from decimal import Decimal
from datetime import date, datetime


def encode(data: Any, delimiter: str = ",", length_marker: bool = False) -> str:
    """
    Codifica datos Python a formato TOON
    
    Args:
        data: Datos a codificar (dict, list, etc.)
        delimiter: Delimitador de campos (',', '\t', '|')
        length_marker: Si incluir marcadores [#N] de longitud
    
    Returns:
        String en formato TOON
    """
    if isinstance(data, dict):
        return _encode_dict(data, delimiter, length_marker)
    elif isinstance(data, list):
        return _encode_list(data, delimiter, length_marker)
    else:
        return str(data)


def _encode_dict(data: Dict, delimiter: str, length_marker: bool, prefix: str = "") -> str:
    """Codifica un diccionario a TOON"""
    lines = []
    
    for key, value in data.items():
        full_key = f"{prefix}{key}" if prefix else key
        
        if isinstance(value, list) and value and isinstance(value[0], dict):
            # Lista de objetos → formato tabular
            lines.append(_encode_table(full_key, value, delimiter, length_marker))
        elif isinstance(value, dict):
            # Diccionario anidado
            lines.append(_encode_dict(value, delimiter, length_marker, f"{full_key}."))
        elif isinstance(value, list):
            # Lista simple
            length_str = f"[#{len(value)}]" if length_marker else f"[{len(value)}]"
            items = delimiter.join(_safe_str(item) for item in value)
            lines.append(f"{full_key}{length_str}: {items}")
        else:
            # Valor simple
            lines.append(f"{full_key}: {_safe_str(value)}")
    
    return "\n".join(lines)


def _encode_table(key: str, data: List[Dict], delimiter: str, length_marker: bool) -> str:
    """Codifica una lista de objetos como tabla TOON"""
    if not data:
        return f"{key}[0]: (empty)"
    
    # Obtener campos únicos de todos los objetos
    all_fields = set()
    for item in data:
        all_fields.update(item.keys())
    
    fields = sorted(all_fields)
    
    # Header
    length_str = f"[#{len(data)}]" if length_marker else f"[{len(data)}]"
    header = f"{key}{length_str}" + "{" + delimiter.join(fields) + "}:"
    
    # Rows
    rows = []
    for item in data:
        row_values = [_safe_str(item.get(field, "")) for field in fields]
        rows.append(delimiter.join(row_values))
    
    return header + "\n" + "\n".join(rows)


def _encode_list(data: List, delimiter: str, length_marker: bool) -> str:
    """Codifica una lista a TOON"""
    if not data:
        return "data[0]: (empty)"
    
    if isinstance(data[0], dict):
        return _encode_table("data", data, delimiter, length_marker)
    else:
        length_str = f"[#{len(data)}]" if length_marker else f"[{len(data)}]"
        items = delimiter.join(_safe_str(item) for item in data)
        return f"data{length_str}: {items}"


def _safe_str(value: Any) -> str:
    """Convierte un valor a string de forma segura"""
    if value is None:
        return ""
    elif isinstance(value, (int, float, Decimal)):
        return str(value)
    elif isinstance(value, (date, datetime)):
        return value.isoformat()
    elif isinstance(value, bool):
        return "true" if value else "false"
    elif isinstance(value, str):
        # Escapar delimitadores y saltos de línea
        value = value.replace("\n", "\\n").replace("\r", "")
        # Solo agregar comillas si contiene delimitadores o espacios problemáticos
        if "," in value or "|" in value or "\t" in value or value.startswith(" ") or value.endswith(" "):
            return f'"{value}"'
        return value
    else:
        return str(value)


def decode(toon_str: str, delimiter: str = ",") -> Union[Dict, List]:
    """
    Decodifica formato TOON a Python
    
    Args:
        toon_str: String en formato TOON
        delimiter: Delimitador usado en la codificación
    
    Returns:
        Dict o List con los datos decodificados
    """
    lines = [line.strip() for line in toon_str.strip().split("\n") if line.strip()]
    
    if not lines:
        return {}
    
    result = {}
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Detectar tabla (key[N]{fields}:)
        if "{" in line and "}" in line and ":" in line:
            table_result, rows_consumed = _decode_table(lines[i:], delimiter)
            
            # Extraer nombre de la tabla
            table_name = line.split("[")[0]
            result[table_name] = table_result
            i += rows_consumed
        
        # Detectar lista simple (key[N]: values)
        elif "[" in line and "]" in line and ":" in line:
            key, values = _decode_list(line, delimiter)
            result[key] = values
            i += 1
        
        # Valor simple (key: value)
        elif ":" in line:
            key, value = line.split(":", 1)
            result[key.strip()] = _parse_value(value.strip())
            i += 1
        
        else:
            i += 1
    
    return result


def _decode_table(lines: List[str], delimiter: str) -> tuple:
    """Decodifica una tabla TOON"""
    header = lines[0]
    
    # Extraer campos del header: key[N]{field1,field2}:
    fields_start = header.index("{")
    fields_end = header.index("}")
    fields = [f.strip() for f in header[fields_start + 1:fields_end].split(delimiter)]
    
    # Extraer cantidad esperada
    length_start = header.index("[")
    length_end = header.index("]")
    length_str = header[length_start + 1:length_end]
    expected_rows = int(length_str.replace("#", ""))
    
    # Parsear filas
    rows = []
    row_idx = 1
    
    while row_idx < len(lines) and len(rows) < expected_rows:
        line = lines[row_idx]
        
        # Si la línea es otra tabla/sección, terminar
        if "{" in line or ":" in line and not line.startswith(delimiter):
            break
        
        # Parsear valores de la fila
        values = [v.strip().strip('"') for v in line.split(delimiter)]
        
        if len(values) == len(fields):
            row_dict = {fields[i]: _parse_value(values[i]) for i in range(len(fields))}
            rows.append(row_dict)
        
        row_idx += 1
    
    return rows, row_idx


def _decode_list(line: str, delimiter: str) -> tuple:
    """Decodifica una lista simple"""
    key, values_str = line.split(":", 1)
    key = key.split("[")[0].strip()
    
    values = [_parse_value(v.strip().strip('"')) for v in values_str.split(delimiter)]
    
    return key, values


def _parse_value(value: str) -> Any:
    """Parsea un valor string a su tipo apropiado"""
    value = value.strip()
    
    if not value or value == "":
        return None
    elif value == "true":
        return True
    elif value == "false":
        return False
    elif value.isdigit():
        return int(value)
    elif _is_float(value):
        return float(value)
    else:
        return value.replace("\\n", "\n")


def _is_float(value: str) -> bool:
    """Verifica si un string es un float válido"""
    try:
        float(value)
        return "." in value or "e" in value.lower()
    except ValueError:
        return False


def estimate_token_savings(json_str: str, toon_str: str) -> Dict[str, Any]:
    """
    Estima el ahorro de tokens entre JSON y TOON
    Usa aproximación: 1 token ≈ 4 caracteres
    
    Returns:
        Dict con estadísticas de ahorro
    """
    json_chars = len(json_str)
    toon_chars = len(toon_str)
    
    # Aproximación de tokens (1 token ≈ 4 chars para inglés, ≈ 3 para texto denso)
    json_tokens = json_chars / 3.5
    toon_tokens = toon_chars / 3.5
    
    savings = json_tokens - toon_tokens
    savings_percent = (savings / json_tokens * 100) if json_tokens > 0 else 0
    
    return {
        "json_chars": json_chars,
        "toon_chars": toon_chars,
        "json_tokens_approx": int(json_tokens),
        "toon_tokens_approx": int(toon_tokens),
        "tokens_saved": int(savings),
        "savings_percent": round(savings_percent, 2),
        "compression_ratio": round(json_chars / toon_chars, 2) if toon_chars > 0 else 0
    }


# Ejemplo de uso
if __name__ == "__main__":
    # Datos de ejemplo
    sample_data = {
        "users": [
            {"id": 1, "name": "Alice", "role": "admin", "active": True},
            {"id": 2, "name": "Bob", "role": "user", "active": True},
            {"id": 3, "name": "Charlie", "role": "user", "active": False}
        ],
        "total_count": 3,
        "timestamp": "2025-11-17T12:00:00"
    }
    
    # Encode
    print("=== TOON Format ===")
    toon_output = encode(sample_data, length_marker=True)
    print(toon_output)
    print()
    
    # Compare sizes
    json_output = json.dumps(sample_data, indent=2)
    print("=== Token Savings ===")
    stats = estimate_token_savings(json_output, toon_output)
    print(f"JSON tokens: {stats['json_tokens_approx']}")
    print(f"TOON tokens: {stats['toon_tokens_approx']}")
    print(f"Saved: {stats['tokens_saved']} tokens ({stats['savings_percent']}%)")
    print(f"Compression: {stats['compression_ratio']}x")
    print()
    
    # Decode
    print("=== Decoded Back ===")
    decoded = decode(toon_output)
    print(json.dumps(decoded, indent=2))
