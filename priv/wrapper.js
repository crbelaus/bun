const command = process.argv.slice(2)

const sub = Bun.spawn(command, {
  stdout: 'inherit',
  stderr: 'inherit',
  stdin: 'pipe',
  onExit: (_, code) => process.exit(code)
})

process.stdin.on('data', (chunk) => sub.stdin.write(chunk))
process.stdin.on('close', () => {
  sub.stdin.end()
  sub.kill()
})
