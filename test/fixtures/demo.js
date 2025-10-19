// Demo script that shows various operations
const args = process.argv.slice(2);
const operation = args[0] || "hello";

switch (operation) {
  case "hello":
    console.log("Hello from Bun!");
    break;
  case "add":
    const sum = args.slice(1).reduce((acc, val) => acc + parseInt(val, 10), 0);
    console.log(sum);
    break;
  case "reverse":
    const text = args.slice(1).join(" ");
    console.log(text.split("").reverse().join(""));
    break;
  default:
    console.log(`Unknown operation: ${operation}`);
}
