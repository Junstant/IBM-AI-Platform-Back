import re
from typing import List, Dict, Any, Optional

def extract_sql_from_response(response: str) -> str:
    """
    Extract SQL query from the LLM response, handling various edge cases:
    - Regular code blocks with ```sql ... ```
    - Nested or malformed blocks with duplicated backticks
    - Multiple sets of backticks (```sql ``` ```sql ...)
    - Code blocks without explicit sql tag
    - Plain SQL without code blocks

    Returns the clean SQL query or an empty string if no valid SQL code block is found.
    """
    print(f"DEBUG: Raw LLM response: {response[:500]}...")  # Debug line
    
    # First, try to find SQL code blocks
    sql_block_patterns = [
        r'```sql\s*(.*?)\s*```',      # ```sql ... ```
        r'```\s*(SELECT.*?;)\s*```',   # ``` SELECT ... ```
        r'```\s*(INSERT.*?;)\s*```',   # ``` INSERT ... ```
        r'```\s*(UPDATE.*?;)\s*```',   # ``` UPDATE ... ```
        r'```\s*(DELETE.*?;)\s*```',   # ``` DELETE ... ```
        r'```\s*(WITH.*?;)\s*```',     # ``` WITH ... ```
    ]
    
    for pattern in sql_block_patterns:
        matches = re.findall(pattern, response, re.DOTALL | re.IGNORECASE)
        if matches:
            sql_query = matches[0].strip()
            print(f"DEBUG: Found SQL in code block: {sql_query[:100]}...")
            return clean_sql_query(sql_query)
    
    # If no code blocks, try to extract SQL statements directly
    sql_patterns = [
        r'(SELECT.*?;)',
        r'(INSERT.*?;)', 
        r'(UPDATE.*?;)',
        r'(DELETE.*?;)',
        r'(WITH.*?;)',
    ]
    
    for pattern in sql_patterns:
        matches = re.findall(pattern, response, re.DOTALL | re.IGNORECASE)
        if matches:
            sql_query = matches[0].strip()
            print(f"DEBUG: Found SQL directly: {sql_query[:100]}...")
            return clean_sql_query(sql_query)
    
    # If still nothing, try a more flexible approach
    # Look for SQL keywords and try to extract everything until semicolon
    sql_keywords = ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'WITH']
    
    for keyword in sql_keywords:
        pattern = rf'\b{keyword}\b.*?;'
        matches = re.findall(pattern, response, re.DOTALL | re.IGNORECASE)
        if matches:
            sql_query = matches[0].strip()
            print(f"DEBUG: Found SQL with keyword {keyword}: {sql_query[:100]}...")
            return clean_sql_query(sql_query)
    
    print("DEBUG: No SQL found in response")
    return ""

def clean_sql_query(sql_query: str) -> str:
    """Clean and normalize SQL query"""
    # Remove leading/trailing whitespace
    sql_query = sql_query.strip()
    
    # Remove any remaining ``` or sql markers
    sql_query = re.sub(r'^```(?:sql)?', '', sql_query)
    sql_query = re.sub(r'```$', '', sql_query)
    
    # Remove any leading "sql" keyword if it appears alone
    sql_query = re.sub(r'^sql\s+', '', sql_query, flags=re.IGNORECASE)
    
    # Ensure it ends with semicolon
    if sql_query and not sql_query.endswith(';'):
        sql_query += ';'
    
    return sql_query.strip()