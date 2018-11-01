import typing
import json
import subprocess
from defx.base.column import Base
from defx.context import Context
from neovim import Nvim
from functools import cmp_to_key

class Column(Base):

    def __init__(self, vim: Nvim) -> None:
        super().__init__(vim)

        self.name = 'diagnostic'

    def get(self, context: Context, candidate: dict) -> str:
        default = ' '
        candidate_path = str(candidate['action__path'])

        if candidate.get('is_root', False):
            self.vim.call('diagnostics#start', candidate_path)
            return default

        diagnostics = self.vim.call('diagnostics#get', candidate_path)
        for diagnostic in diagnostics:
            if diagnostic['path'].startswith(candidate_path):
                return '!'

        return default

    def length(self, context: Context) -> int:
        return 1

