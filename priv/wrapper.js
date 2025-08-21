const command = process.argv.slice(2)

const sub = Bun.spawn(command, {
  stdout: 'inherit',
  stderr: 'inherit',
  stdin: Bun.stdin.stream(),
  onExit: (_, code) => process.exit(code)
})

process.stdin.resume()
process.stdin.on('close', () => sub.kill());
