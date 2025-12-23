from typing import Iterable


def split_sql_statements(sql: str) -> Iterable[str]:
    statements: list[str] = []
    buffer: list[str] = []
    idx = 0
    in_dollar = False
    tag = ""

    while idx < len(sql):
        ch = sql[idx]
        next_two = sql[idx : idx + 2]

        if not in_dollar and ch == "$":
            end = sql.find("$", idx + 1)
            if end != -1:
                tag = sql[idx : end + 1]
                buffer.append(tag)
                idx = end + 1
                in_dollar = True
                continue

        if in_dollar and tag and sql.startswith(tag, idx):
            buffer.append(tag)
            idx += len(tag)
            in_dollar = False
            tag = ""
            continue

        if ch == ";" and not in_dollar:
            statement = "".join(buffer).strip()
            if statement:
                statements.append(statement)
            buffer = []
            idx += 1
            continue

        buffer.append(ch)
        idx += 1

    tail = "".join(buffer).strip()
    if tail:
        statements.append(tail)

    return statements
