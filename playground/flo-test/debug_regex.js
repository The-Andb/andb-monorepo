const pattern = "@flodev.net";
const replacement = "@flouat.net";
const regex = new RegExp(pattern, 'g');
const src = "CREATE VIEW `v_test` AS SELECT * FROM helper_users WHERE email LIKE '%@flodev.net';\n";
const result = src.replace(regex, replacement);
console.log('Original:', src);
console.log('Regex:', regex);
console.log('Result:', result);
console.log('Match:', src.match(regex));
