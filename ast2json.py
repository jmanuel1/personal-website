from ast import AST, iter_fields, parse
from json import JSONEncoder
from sys import stdin


class ASTEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, AST):
            return ast_to_dict(obj)
        return super().default(obj)


def ast_to_dict(tree):
    if isinstance(tree, AST):
        d = {field: ast_to_dict(value) for field, value in iter_fields(tree)}
        d['__type__'] = type(tree).__name__
        return d
    elif isinstance(tree, list):
        return [ast_to_dict(value) for value in tree]
    return tree


tree = parse(stdin.read())
print(ASTEncoder().encode(tree))
