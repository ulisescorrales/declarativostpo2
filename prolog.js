// let Prolog;
// let Module;
// const options = {};

// SWIPL(options).then(async (module) => {
//     Module = module;
//     Prolog = Module.prolog;

//     try {
//         // 1. Descargas el archivo desde tu localhost
//         const response = await fetch("http://localhost:8316/prueba.pl");
//         const code = await response.text();

//         // 2. Lo escribes en el sistema de archivos virtual de WASM
//         Module.FS.writeFile('/prueba.pl', code);

//         // 3. Ahora sí, lo consultas desde el FS virtual
//         Prolog.consult("/prueba.pl");
// 		console.log(code)
        
//         console.log("Archivo consultado con éxito.");
// //     } catch (error) {
// //         console.error("Error cargando el archivo Prolog:", error);
// //     }
// });
var session = pl.create();
fetch("http://localhost:8316/prueba.pl")
  .then(res => res.text())
  .then(prologCode => {

	console.log(prologCode)
    session.consult(prologCode, {
      success: () => {
        console.log("Program loaded!");
      },
      error: (err) => {
        console.error("Consult error:", err);
      }
    });

  });
function ejecutarProlog() {
    // Es vital añadir el punto '.' al final de la consulta
    session.query("escribir_hola.", {
        success: function() {
            // Buscamos la solución. Al encontrarla, el módulo DOM aplicará los cambios.
            session.answer({
                success: function(answer) {
                    console.log("Predicado ejecutado con éxito.");
                },
                fail: function() {
                    console.log("El predicado falló (devolvió false).");
                },
                error: function(err) {
                    console.error("Error al intentar resolver la consulta:", err);
                }
            });
        },
        error: function(err) {
            console.error("Error en el formato de la query:", err);
        }
    });
}
