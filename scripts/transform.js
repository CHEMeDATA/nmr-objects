#!/usr/bin/env node
// file: transform.js

import fs from "fs/promises";
import path from "path";
import fetch from "node-fetch";

const SRC_DIR = "src";
const DIST_DIR = "dist";
const SCRATCH_DIR = "scratch";
const BODY_STATEMENT = "extraMethodsStatements";
const ORG = "CHEMeDATA";

export async function transform() {
	console.log("");
	console.log("**************************************************** ");
	console.log("**************************************************** ");
	console.log("**************************************************** ");
	console.log("**************************************************** ");
	console.log("****** Start scripts/transform.js ");

	// Reset dist directory
	await fs.rm(DIST_DIR, { recursive: true, force: true });
	await fs.mkdir(DIST_DIR, { recursive: true });

	for (const TYPE of ["import", "export", "viewer", "bridge"]) {
		const fileInScratch = path.join(SCRATCH_DIR, `${TYPE}.txt`);
		console.log(`** Processing <${TYPE}> objects from ${fileInScratch} **`);

		let lines;
		try {
			lines = (await fs.readFile(fileInScratch, "utf8"))
				.split("\n")
				.filter(Boolean);
		} catch {
			continue; // skip if file missing or empty
		}

		for (const OBJ of lines) {
			if (!OBJ || OBJ.startsWith("//") || OBJ.startsWith("#")) continue;

			console.log(`    Processing <${TYPE}> object: ${OBJ}`);

			const objGitPointer = `https://raw.githubusercontent.com/${ORG}/${OBJ}/main`;
			const objDir = path.join(SRC_DIR, OBJ);
			await fs.mkdir(objDir, { recursive: true });

			// download extraMethodsStatements.json
			const jsonUrl = `${objGitPointer}/${BODY_STATEMENT}.json`;
			const jsonPath = path.join(objDir, `${BODY_STATEMENT}.json`);

			let json;
			try {
				const res = await fetch(jsonUrl);
				if (!res.ok) throw new Error(`❌ Fetch failed ${jsonUrl}`);
				json = await res.json();
				await fs.writeFile(jsonPath, JSON.stringify(json, null, 2));
			} catch {
				console.log(`❌-----failed to get ${jsonUrl}`);
				continue;
			}

			// Build .txt from listObject
			const entries = (json.listObject || []).map(
				(o) => `${o.object} ${o.type}`
			);
			await fs.writeFile(
				path.join(objDir, `${BODY_STATEMENT}.txt`),
				entries.join("\n")
			);

			// Download js libraries if any
			if (Array.isArray(json.jsLibrary)) {
				for (const lib of json.jsLibrary) {
					console.log(`         Processing library: ${lib}`);
					const libPath = path.join(DIST_DIR, lib);
					if (!(await exists(libPath))) {
						const libUrl = `${objGitPointer}/src/${lib}`;
						await downloadToFile(libUrl, libPath);
					} else {
						console.log(`${lib} already exists in ${DIST_DIR}, skipping.`);
					}

					// Append metadata as comment
					const editor = json.creatorParam?.editor ?? "NA";
					const version = json.creatorParam?.version ?? "NA";
					const source = json.creatorParam?.source ?? "NA";
					const id = json.creatorParam?.id ?? "NA";
					const result = `Editor${editor}_Version${version}_Source${source}_ID${id}`;
					await fs.appendFile(libPath, `\n// for ${result}\n`);
				}
			}

			// Process object statements
			for (const entry of entries) {
				const [objectStatement, typeStatement] = entry.split(" ");
				if (!objectStatement) continue;
				// no insertion for "viewers"
				if (typeStatement !== TYPE || typeStatement === "viewer") continue;
				if (!["import", "export", "viewer", "bridge"].includes(typeStatement)) continue;

				console.log(`                          Object : ${objectStatement} (entry: ${entry})`);

				// Download helper scripts
				const statementsFile = `${typeStatement}Statements.js`;
				const methodFile = `${typeStatement}Method.js`;
				const statementsUrl = `${objGitPointer}/src/${statementsFile}`;
				const methodUrl = `${objGitPointer}/src/${methodFile}`;

				const statementsPath = path.join(objDir, statementsFile);
				const methodPath = path.join(objDir, methodFile);

				await downloadToFile(statementsUrl, statementsPath);
				await downloadToFile(methodUrl, methodPath);

				// Copy target base file into dist if not present
				const baseFileSrc = path.join(SRC_DIR, `${objectStatement}.js`);
				const baseFileDist = path.join(DIST_DIR, `${objectStatement}.js`);
				if (!(await exists(baseFileDist))) {
					try {
						await fs.copyFile(baseFileSrc, baseFileDist);
						console.log(`✅Copied ${objectStatement}.js into dist`);
					} catch {
						console.error(
							`!! Warning: File ${baseFileSrc} missing — target class does not exist - This may be OK!`
						);
						console.log(`             NO Insertions of ${statementsFile} `);
						console.log(`             NO and           ${methodFile} `);
						console.log(`             NO into          ${objectStatement}.js`);
						continue;
					}
				}

				// Insertions into dist file
				console.log(`             Insertions of ${statementsFile} `);
				console.log(`             and           ${methodFile} `);
				console.log(`             into          ${objectStatement}.js`);
				let distCode = await fs.readFile(baseFileDist, "utf8");
				const statementsCode = await fs.readFile(statementsPath, "utf8");
				const methodCode = await fs.readFile(methodPath, "utf8");

				distCode = distCode.replace(
					/\/\/ AUTOMATIC IMPORT INSERTION WILL BE MADE HERE/,
					`// AUTOMATIC IMPORT INSERTION WILL BE MADE HERE\n${statementsCode}`
				);
				distCode = distCode.replace(
					/\/\/ AUTOMATIC METHOD INSERTION WILL BE MADE HERE/,
					`// AUTOMATIC METHOD INSERTION WILL BE MADE HERE\n${methodCode}`
				);

				await fs.writeFile(baseFileDist, distCode);
			}
		}
	}
	console.log("transform.js finished");
}

async function exists(file) {
	try {
		await fs.access(file);
		return true;
	} catch {
		return false;
	}
}

async function downloadToFile(url, file) {
	try {
		const res = await fetch(url);
		if (!res.ok) throw new Error(`bad fetch ${url}`);
		const text = await res.text();
		await fs.writeFile(file, text);
	} catch (err) {
		console.log(`❌ ERROR: File ${url} missing or empty`);
	}
}

// Run directly
	transform().catch((err) => {
		console.error("❌Error:", err);
		process.exit(1);
	});

