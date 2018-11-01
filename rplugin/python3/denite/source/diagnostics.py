from .base import Base
import time

class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)
        self.vim = vim

        self.name = 'diagnostics'
        self.kind = 'file'
        self.time = 0
        self.candidates = []

    def on_init(self, context):
        path = context['args'][0] if len(context['args']) == 1 else self.vim.call('getcwd')
        self.vim.call('diagnostics#start', path)

    def gather_candidates(self, context):
        path = context['args'][0] if len(context['args']) == 1 else self.vim.call('getcwd')

        detect = self.vim.call('diagnostics#detect', path)
        if 'cwd' not in detect:
            return []

        context['all_candidates'] = []

        current_time = time.time() * 1000
        if (current_time - self.time) <= 500:
            return self.candidates
        self.time = current_time

        context['is_async'] = True

        candidates = self.vim.call('diagnostics#get', detect['cwd'])
        candidates = self.convert(detect['cwd'], candidates)
        self.candidates = candidates
        return candidates

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

