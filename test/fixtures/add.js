// Module that adds two numbers
const args = process.argv.slice(2);
const a = parseInt(args[0] || "0", 10);
const b = parseInt(args[1] || "0", 10);
console.log(a + b);
