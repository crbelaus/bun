// Simple test module that echoes arguments
const args = process.argv.slice(2);
if (args.length === 0) {
  console.log("Hello from bun!");
} else {
  console.log(args.join(" "));
}
