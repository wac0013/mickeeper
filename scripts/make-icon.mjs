// Gera Resources/AppIcon.icns a partir de assets/icon.svg (rodar em qualquer SO).
// Uso: npm i --no-save @resvg/resvg-js && node scripts/make-icon.mjs
import { Resvg } from "@resvg/resvg-js";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";

const svg = readFileSync("assets/icon.svg");
const png = (size) => new Resvg(svg, { fitTo: { mode: "width", value: size } }).render().asPng();

// tipo ICNS -> lado em px (os @2x reaproveitam o PNG do dobro do tamanho)
const chunks = [
  ["icp4", 16], ["icp5", 32], ["ic12", 64], ["ic07", 128], ["ic13", 256],
  ["ic08", 256], ["ic14", 512], ["ic09", 512], ["ic10", 1024],
];

const body = chunks.map(([type, size]) => {
  const data = png(size);
  const head = Buffer.alloc(8);
  head.write(type, 0, "ascii");
  head.writeUInt32BE(data.length + 8, 4);
  return Buffer.concat([head, data]);
});
const total = 8 + body.reduce((n, b) => n + b.length, 0);
const header = Buffer.alloc(8);
header.write("icns", 0, "ascii");
header.writeUInt32BE(total, 4);

mkdirSync("Resources", { recursive: true });
writeFileSync("Resources/AppIcon.icns", Buffer.concat([header, ...body]));
console.log(`Resources/AppIcon.icns (${total} bytes)`);
