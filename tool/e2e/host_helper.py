#!/usr/bin/env python3
"""Host-side helper for the FITRIX e2e harness.

The integration test runs inside the iOS Simulator, which shares the Mac's
network, so it calls this server on 127.0.0.1:8765 to do what only the host
can: simulator screenshots/videos, simulated GPS, backgrounding the app, and
reading the sign-in code from the local Supabase mail catcher (Mailpit).

Usage: python3 tool/e2e/host_helper.py --udid <UDID> --out <dir>
"""
import argparse, json, os, re, signal, subprocess, threading, time, urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

ap = argparse.ArgumentParser()
ap.add_argument('--udid', required=True)
ap.add_argument('--out', required=True)
ap.add_argument('--port', type=int, default=8765)
ap.add_argument('--mailpit', default='http://127.0.0.1:55324')
ap.add_argument('--bundle', default='com.elibayev.fitrix')
ap.add_argument('--backend-port', type=int, default=3100,
                help='the e2e Felix backend (never the live one on 3000)')
ap.add_argument('--backend-dir', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'backend'))
args = ap.parse_args()
os.makedirs(os.path.join(args.out, 'shots'), exist_ok=True)
os.makedirs(os.path.join(args.out, 'videos'), exist_ok=True)
STEPS = os.path.join(args.out, 'steps.log')
counter = [len(os.listdir(os.path.join(args.out, 'shots')))]
video = {}
lock = threading.Lock()

SIMCTL = subprocess.run(['xcrun', '-f', 'simctl'], capture_output=True, text=True).stdout.strip() or 'simctl'

def stop_video(pr):
    try:
        os.killpg(pr.pid, signal.SIGINT)
    except Exception:
        pr.send_signal(signal.SIGINT)
    try:
        pr.wait(60)
    except Exception:
        os.killpg(pr.pid, signal.SIGTERM)

def log(msg):
    with open(STEPS, 'a') as f:
        f.write('%s %s\n' % (time.strftime('%H:%M:%S'), msg))

def simctl(*a, check=False):
    r = subprocess.run(['xcrun', 'simctl', *a], capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr).strip()

def safe(name):
    return re.sub(r'[^A-Za-z0-9_.-]+', '_', name)[:80]

def latest_msg(email):
    q = urllib.request.quote('to:%s' % email)
    with urllib.request.urlopen('%s/api/v1/search?query=%s&limit=1' % (args.mailpit, q), timeout=5) as r:
        msgs = json.load(r).get('messages', [])
    return msgs[0]['ID'] if msgs else ''

marks = {}

def otp(email):
    """The 6-digit code from the newest mail to [email] newer than the mark."""
    for _ in range(40):
        try:
            mid = latest_msg(email)
            if mid and mid != marks.get(email):
                with urllib.request.urlopen('%s/api/v1/message/%s' % (args.mailpit, mid), timeout=5) as r:
                    body = json.load(r)
                text = (body.get('Text') or '') + ' ' + re.sub('<[^>]+>', ' ', body.get('HTML') or '')
                codes = re.findall(r'(?<!\d)(\d{6})(?!\d)', text)
                if codes:
                    marks[email] = mid
                    return codes[0]
        except Exception as e:
            log('otp error %s' % e)
        time.sleep(1)
    return ''

class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def reply(self, code, body):
        b = body.encode() if isinstance(body, str) else body
        self.send_response(code)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        u = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(u.query).items()}
        p = u.path
        try:
            if p == '/ping':
                return self.reply(200, 'pong')
            if p == '/log':
                log(q.get('msg', ''))
                return self.reply(200, 'ok')
            if p == '/shot':
                with lock:
                    counter[0] += 1
                    n = counter[0]
                fn = os.path.join(args.out, 'shots', '%03d_%s.png' % (n, safe(q.get('name', 'shot'))))
                rc, out = simctl('io', args.udid, 'screenshot', fn)
                log('SHOT %s rc=%s' % (os.path.basename(fn), rc))
                return self.reply(200 if rc == 0 else 500, fn if rc == 0 else out)
            if p == '/video/start':
                name = safe(q.get('name', 'video'))
                if 'p' in video:
                    stop_video(video.pop('p'))
                fn = os.path.join(args.out, 'videos', '%s.mov' % name)
                if os.path.exists(fn):
                    os.remove(fn)
                # simctl itself (not the xcrun wrapper, which does not pass
                # SIGINT on) in its own process group, so stop reaches it.
                video['p'] = subprocess.Popen([SIMCTL, 'io', args.udid, 'recordVideo', '--codec=h264', '--force', fn],
                                              stdout=subprocess.DEVNULL, stderr=open(fn + '.log', 'w'),
                                              start_new_session=True)
                video['fn'] = fn
                time.sleep(1.5)  # recordVideo needs a moment before the first frame
                log('VIDEO START %s' % name)
                return self.reply(200, fn)
            if p == '/video/stop':
                pr = video.pop('p', None)
                if pr:
                    time.sleep(0.5)
                    stop_video(pr)
                log('VIDEO STOP %s' % video.get('fn'))
                return self.reply(200, video.get('fn', ''))
            if p == '/loc/start':
                pts = q['pts'].split(';')
                a = ['location', args.udid, 'start']
                if 'speed' in q:
                    a.append('--speed=%s' % q['speed'])
                if 'interval' in q:
                    a.append('--interval=%s' % q['interval'])
                rc, out = simctl(*a, *pts)
                log('LOC START %s pts rc=%s %s' % (len(pts), rc, out))
                return self.reply(200 if rc == 0 else 500, out)
            if p == '/loc/set':
                rc, out = simctl('location', args.udid, 'set', '%s,%s' % (q['lat'], q['lon']))
                log('LOC SET rc=%s' % rc)
                return self.reply(200 if rc == 0 else 500, out)
            if p == '/loc/clear':
                rc, out = simctl('location', args.udid, 'clear')
                log('LOC CLEAR rc=%s' % rc)
                return self.reply(200, out)
            if p == '/bg':
                secs = float(q.get('seconds', '10'))
                other = q.get('app', 'com.apple.Preferences')
                def run():
                    simctl('launch', args.udid, other)
                    log('BG launched %s for %ss' % (other, secs))
                    time.sleep(secs / 2)
                    simctl('io', args.udid, 'screenshot', os.path.join(args.out, 'shots', 'bg_%d.png' % int(time.time())))
                    time.sleep(secs / 2)
                    simctl('launch', args.udid, args.bundle)
                    log('BG returned to %s' % args.bundle)
                threading.Thread(target=run, daemon=True).start()
                return self.reply(200, 'scheduled')
            if p == '/otp/mark':
                marks[q['email']] = latest_msg(q['email'])
                return self.reply(200, marks[q['email']] or '-')
            if p == '/otp':
                code = otp(q['email'])
                log('OTP for %s -> %s' % (q['email'], 'found' if code else 'none'))
                return self.reply(200 if code else 404, code)
            if p == '/backend':
                # Stops/starts only the e2e backend, for the Felix error path.
                port = args.backend_port
                if port == 3000:
                    return self.reply(400, 'refusing to touch port 3000')
                if q.get('action') == 'stop':
                    r = subprocess.run(['lsof', '-ti', 'tcp:%d' % port, '-sTCP:LISTEN'], capture_output=True, text=True)
                    pids = [x for x in r.stdout.split() if x.strip()]
                    for pid in pids:
                        os.kill(int(pid), signal.SIGTERM)
                    log('BACKEND STOP port=%d pids=%s' % (port, pids))
                    return self.reply(200, 'stopped %s' % pids)
                if q.get('action') == 'start':
                    env = dict(os.environ, SUPABASE_URL='http://127.0.0.1:55321', PORT=str(port))
                    logf = open(os.path.join(args.out, 'backend%d.log' % port), 'a')
                    pr = subprocess.Popen(['node', 'server.js'], cwd=args.backend_dir, env=env,
                                          stdout=logf, stderr=logf, start_new_session=True)
                    with open(os.path.join(args.out, 'backend%d.pid' % port), 'w') as f:
                        f.write(str(pr.pid))
                    time.sleep(2)
                    log('BACKEND START port=%d pid=%d' % (port, pr.pid))
                    return self.reply(200, 'started %d' % pr.pid)
                return self.reply(400, 'action=stop|start')
            if p == '/grant':
                out = []
                for svc in q.get('services', 'location').split(','):
                    rc, o = simctl('privacy', args.udid, 'grant', svc, args.bundle)
                    out.append('%s rc=%s %s' % (svc, rc, o))
                log('GRANT ' + ' | '.join(out))
                return self.reply(200, '\n'.join(out))
            if p == '/simctl':
                rc, out = simctl(*q['args'].split(' '))
                log('SIMCTL %s rc=%s' % (q['args'], rc))
                return self.reply(200 if rc == 0 else 500, out)
            return self.reply(404, 'unknown')
        except Exception as e:
            log('ERR %s %s' % (p, e))
            return self.reply(500, str(e))

log('helper start udid=%s' % args.udid)
ThreadingHTTPServer(('127.0.0.1', args.port), H).serve_forever()
