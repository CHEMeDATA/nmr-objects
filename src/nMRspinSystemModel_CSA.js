// AUTOMATIC IMPORT INSERTION WILL BE MADE HERE
// include for bridge from solidStateNMRCSA-reader

import { ObjectBase } from "./objectBase.js";

export class NMRspinSystemModel_CSA extends ObjectBase {
	constructor(param, input) {
		super(param, input, "NMRspinSystemModel_CSA");
		// optionally override again
		this.verbose = 0;
	}

	_handleLoadDemoData(demoParam) {
		this._loadDemoData(demoParam);
	}

	_loadDemoData(demoParam = {}) {
		var spins = [];
		for (const elem of demoParam) {
			const diagTensorValues = {
				wildComment:
					"Created by schema/scripts/createSchemaSomeInstances.js using function createInstance",
				xx: elem[0],
				yy: elem[1],
				zz: elem[2],
			};
			const spin = {
				wildComment:
					"Created by schema/scripts/createSchemaSomeInstances.js using function createInstance",
				typeVariableString: "ChemicalShift",
				diagTensorValues: diagTensorValues,
			};
			spins.push(spin);
		}

		const full = {
			$schema:
				"https://chemedata.github.io/schema/v1/schema/NMRspinSystemModel_CSA.json",
			wildComment: "Created by demo option ",
			spins: spins,
		};

		this.data = full;
	}

// AUTOMATIC METHOD INSERTION WILL BE MADE HERE

}
