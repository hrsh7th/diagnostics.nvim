from .base import Base

class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)
        self.vim = vim

        self.name = 'diagnostics'
        self.kind = 'file'

    def gather_candidates(self, context):
        path = context['args'][0] if len(context['args']) == 1 else self.vim.call('getcwd')

        detect = self.vim.call('diagnostics#detect', path)
        if 'cwd' not in detect:
            return []
        diagnostics = self.vim.call('diagnostics#get', detect['cwd'])
        diagnostics = self.convert(detect['cwd'], diagnostics)
        return diagnostics

    def convert(self, cwd, diagnostics):
        max_len = max([20] + [len(x['path'].replace(cwd, '')) for x in diagnostics])

        candidates = []
        for diagnostic in diagnostics:
            word = ('{0:<' + str(max_len + 1) + '}: {1}').format(diagnostic['path'].replace(cwd, ''), diagnostic['message'])
            candidates.append({
                'word': word,
                'abbr': word,
                'action__path': diagnostic['path'],
                'action__line': diagnostic['line'],
                'action__col': diagnostic['col']
            })
        return candidates


