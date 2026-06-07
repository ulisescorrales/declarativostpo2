const ws = new WebSocket("ws://localhost:8316/ws");
ws.onopen = () => {
    console.log("Conectado");
	ws.send('join("Ulises")');
};
// let Prolog;
// let Module;
// const options = {
//   // Provide options for customization
// };

// SWIPL(options).then((module) =>
// { Module = module;
//   Prolog = Module.prolog;

//   Prolog.query("use_module(library(http/websocket)).").once();
// 	Prolog.query("http_open_websocket('ws://localhost:8316/ws', WebSocket, [])").once()

//   // Start using Prolog
// });
// // import SWIPL from './swipl-web.js';
// var swipl;
// async function inicializarProlog() {
// 	try {
// 		console.log("Cargando SWI-Prolog Wasm...");

// 		// Inicializar el módulo pasándole la ubicación de los archivos si es necesario
// 		swipl = await SWIPL({
// 			arguments: ['-q'] // '-q' evita los mensajes de bienvenida innecesarios en la consola
// 		});

// 		console.log("¡SWI-Prolog está listo!");

// 		// --- EJEMPLO 1: Una consulta simple ---
// 		// Vamos a preguntar cuánto es 2 + 2 usando la API de consultas rápidas
// 		const respuesta = swipl.prolog.query("X is 2 + 2.").once();
// 		console.log("Resultado de X is 2 + 2 -> X =", respuesta.X);


// 		// --- EJEMPLO 2: Cargar reglas dinámicamente ---
// 		// Usamos 'assertz' para añadir hechos y reglas en memoria
// 		swipl.prolog.query("assertz(padre(homero, bart))").once();
// 		swipl.prolog.query("assertz(padre(homero, lisa))").once();

// 		// Consultamos todos los hijos de homero
// 		const consultaHijos = swipl.prolog.query("padre(homero, Hijo)");

// 		console.log("Buscando hijos de Homero:");
// 		// Iteramos sobre las soluciones posibles (.next() devuelve cada respuesta)
// 		let solucion;
// 		while ((solucion = consultaHijos.next()) && !solucion.done) {
// 			console.log(`- Es padre de: ${solucion.value.Hijo}`);
// 		}

// 	} catch (error) {
// 		console.error("Error al inicializar SWI-Prolog:", error);
// 	}
// }

// // Ejecutar la función al cargar la página
// inicializarProlog();
