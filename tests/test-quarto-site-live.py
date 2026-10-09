"""Exercise live-preview watching with real watchexec and a small render stub."""
import os
from pathlib import Path
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time
import unittest

HELPER = Path(__file__).resolve().parents[1] / 'bin/quarto-site-live'


class SiteLiveTests(unittest.TestCase):
    @unittest.skipUnless(all(shutil.which(name) for name in
                            ('watchexec', 'browser-sync', 'curl', 'lsof')),
                         'requires the live-preview command dependencies')
    def test_nested_page_saves_render_once_and_generated_files_do_not_loop(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            project = root / 'site'
            project.mkdir()
            (project / '.git').mkdir()
            (project / '_quarto.yml').write_text('project:\n  type: website\n')
            (project / '.gitignore').write_text('/_includes/publications.html\n')
            page = project / 'education-experience/index.qmd'
            page.parent.mkdir()
            page.write_text('# Experience\n')
            redirect = project / 'cv/index.html'
            redirect.parent.mkdir()
            redirect.write_text('<p>Redirect resource</p>')
            commands = root / 'commands'
            commands.mkdir()
            count = root / 'renders.txt'
            render_stub = commands / 'quarto'
            render_stub.write_text(f'#!{sys.executable}\n' + '''
import os
import shutil
import time
from pathlib import Path
root = Path.cwd()
with Path(os.environ['SITE_LIVE_TEST_COUNT']).open('a') as count:
    count.write('render\\n')
# Reproduce Quarto's temporary root files and generated publication include.
temporary = root / '.render-temporary'
temporary.touch()
temporary.unlink()
# Quarto stages page HTML and site_libs in the source tree, then moves them.
page_html = root / 'education-experience/index.html'
page_html.write_text('<p>Temporary page output</p>')
libraries = root / 'site_libs'
libraries.mkdir(exist_ok=True)
(libraries / 'generated.js').write_text('// Temporary JavaScript output')
time.sleep(1.5)
page_html.unlink()
shutil.rmtree(libraries)
(root / '_includes').mkdir(exist_ok=True)
(root / '_includes/publications.html').write_text('<p>Generated</p>')
(root / '_site').mkdir(exist_ok=True)
(root / '_site/index.html').write_text('<html><body>Preview</body></html>')
''')
            render_stub.chmod(0o755)
            with socket.socket() as listener:
                listener.bind(('localhost', 0))
                port = listener.getsockname()[1]
            env = os.environ | {'PATH': str(commands) + os.pathsep + os.environ['PATH'],
                                'QUARTO_PYTHON': sys.executable,
                                'SITE_LIVE_TEST_COUNT': str(count)}
            with (root / 'helper.log').open('w') as log:
                process = subprocess.Popen([str(HELPER), '--no-open', '--port', str(port)],
                                           cwd=project, env=env, stdout=log,
                                           stderr=subprocess.STDOUT, start_new_session=True)
                try:
                    def render_count():
                        return len(count.read_text().splitlines()) if count.exists() else 0

                    def wait_for(predicate):
                        deadline = time.monotonic() + 15
                        while time.monotonic() < deadline:
                            if predicate():
                                return
                            if process.poll() is not None:
                                self.fail((root / 'helper.log').read_text())
                            time.sleep(.1)
                        self.fail('Live preview timed out:\n' + (root / 'helper.log').read_text())

                    wait_for(lambda: 'serving http://' in (root / 'helper.log').read_text())
                    # Give the postponed watcher time to establish its baseline.
                    time.sleep(2)
                    self.assertEqual(render_count(), 1)
                    page.write_text('# Experience\n\nUpdated role.\n')
                    wait_for(lambda: render_count() == 2)
                    time.sleep(3)
                    self.assertEqual(render_count(), 2, 'A render must not trigger another render')
                    (project / '_site/index.html').write_text('<p>Output change</p>')
                    (project / '_includes/publications.html').write_text('<p>Catalog output change</p>')
                    time.sleep(3)
                    self.assertEqual(render_count(), 2, 'Generated output must not trigger a render')
                    redirect.write_text('<p>Updated standalone HTML resource</p>')
                    wait_for(lambda: render_count() == 3)
                    time.sleep(3)
                    self.assertEqual(render_count(), 3, 'Standalone HTML resources must stay watched')
                finally:
                    if process.poll() is None:
                        os.killpg(process.pid, signal.SIGINT)
                        try:
                            process.wait(timeout=15)
                        except subprocess.TimeoutExpired:
                            os.killpg(process.pid, signal.SIGKILL)
                            process.wait()


if __name__ == '__main__':
    unittest.main()
