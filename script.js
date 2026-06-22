//WS
const estadoConexion = document.getElementById('estadoConexion');
const panelIngreso = document.getElementById('panelIngreso');

const socket = new WebSocket('ws://localhost:8316/ws');

socket.onopen = () => {
	console.log('WebSocket abierto');

	estadoConexion.style.display = 'none';
	panelIngreso.style.display = 'block';

	// setInterval(() => {
	// 	socket.send("s(1).");
	// }, 500); // 30 seconds
};

socket.onmessage = (event) => {
	console.log('server: ' + event.data);
	if (event.data == 'elegir') {
		return;
	}
	session.query("procesar_mensaje('" + event.data + "').", {
		success: function (goal) {
			session.answer(console.log);
		},
		error: function (err) {
			console.log(event.data);
			console.log('Error procesando mensaje:' + err);
		}
	});
};

socket.onerror = () => {
	console.log('Error WebSocket');

	estadoConexion.innerHTML = `
		<h2>Error de conexión</h2>
		<p>No fue posible conectarse al servidor WebSocket.</p>
	`;

	panelIngreso.style.display = 'none';
};

socket.onclose = () => {
	if (panelIngreso.style.display === 'none') {
		estadoConexion.innerHTML = `
			<h2>Error de conexión</h2>
			<p>La conexión WebSocket fue cerrada.</p>
		`;
	}
}; //-------------------
let cartaSeleccionada = null;

/* =========================
   TURNO
   ========================= */

function cargarTurno(nombreJugador) {
	document.getElementById('turnoJugador').textContent = nombreJugador;

	if (nombreJugador !== 'tu turno') {
		cargarInstruccion(['espere su turno']);
	} else {
		cargarInstruccion(['Elija una carta de la baraja']);
	}
}
/* =========================
   INSTRUCCIONES
   ========================= */

function cargarInstruccion2(instrucciones) {
	const i2 = instrucciones.split('\n');
	cargarInstruccion(i2);
}
function informarGanadores(ganadores) {
	finDelJuego(ganadores)
}

function cargarInstruccion(instrucciones) {
	console.log('cargarInstruccion:');
	console.log(instrucciones);
	const contenedor = document.getElementById('contenidoInstruccion');

	contenedor.innerHTML = '';

	if (instrucciones.length === 1 && instrucciones[0] === 'espere su turno') {
		document.body.classList.add('turno-espera');
	} else {
		document.body.classList.remove('turno-espera');
	}

	if (instrucciones.length === 1) {
		contenedor.textContent = instrucciones[0];
	} else {
		instrucciones.forEach((texto) => {
			const boton = document.createElement('button');

			boton.textContent = texto;

			boton.value = texto[0];

			boton.onclick = function () {
				accionInstruccion(boton.value);
			};

			contenedor.appendChild(boton);
		});
	}
}
/* =========================
   CARTAS DISPONIBLES
   ========================= */
function cargarCartasDisponiblesTurno(listaCartas) {
	console.log('cargando cartas: ' + listaCartas);
	let listaCartas2 = listaCartas.split(',');
	const contenedor = document.getElementById('cartasDisponibles');

	contenedor.innerHTML = '';

	listaCartas2.forEach((nombre) => {
		const carta = document.createElement('button');

		carta.className = 'carta carta-disponible';
		carta.textContent = nombre;

		contenedor.appendChild(carta);
		carta.onclick = function () {
			seleccionarCartaBaraja(carta);
		};
	});
	habilitarCartasDisponibles();
}

function cargarCartasDisponibles(listaCartas) {
	console.log('cargando cartas: ' + listaCartas);
	let listaCartas2 = listaCartas.split(',');
	const contenedor = document.getElementById('cartasDisponibles');

	contenedor.innerHTML = '';

	listaCartas2.forEach((nombre) => {
		const carta = document.createElement('button');

		carta.className = 'carta carta-disponible';
		carta.disabled = true;
		carta.textContent = nombre;

		contenedor.appendChild(carta);
	});
	deshabilitarCartasDisponibles();
}

/* =========================
   BARAJA DEL JUGADOR
   ========================= */

function cargarCartasBaraja(listaCartas) {
	let listaCartas2;
	if (listaCartas == undefined) {
		listaCartas = [];
	} else {
		listaCartas2 = listaCartas.split(',');
	}
	const contenedor = document.getElementById('barajaJugador');

	contenedor.innerHTML = '';
	document.querySelectorAll('.seleccionada').forEach((elemento) => {
		elemento.classList.remove('seleccionada');
	});

	listaCartas2.forEach((nombre) => {
		const carta = document.createElement('div');

		carta.className = 'carta carta-baraja';

		carta.textContent = nombre;

		carta.onclick = function () {
			seleccionarCartaBaraja(carta);
		};

		contenedor.appendChild(carta);
	});
}

/* =========================
   FLUJO DEL JUEGO
   ========================= */
function pintarSeleccionBaraja(nombreCarta) {
	console.log('pintarCartaBaraja: ' + nombreCarta);
	const baraja = document.getElementById('barajaJugador');

	// Convertimos baraja.children (que es un HTMLCollection) en un array para iterar cómodamente
	for (const elemento of baraja.children) {
		// Comparamos el innerHTML del hijo con el nombreCarta recibido por parámetro
		if (elemento.innerHTML.trim() === nombreCarta) {
			// Si coincide, le añadimos la clase
			elemento.classList.add('seleccionada');

			break; // Rompemos el bucle ya que encontramos la carta
		}
	}
}
function habilitarCartasDisponibles() {
	document.querySelectorAll('.carta-disponible').forEach((carta) => {
		carta.style.cursor = 'pointer';
		carta.disabled = false;
	});
}
function deshabilitarCartasDisponibles() {
	document.querySelectorAll('.carta-disponible').forEach((carta) => {
		carta.style.cursor = 'not-allowed';
		carta.disabled = true;
	});
}
function finDelJuego(ganadores) {
	const instrucciones = document.getElementById('contenidoInstruccion');
	instrucciones.innerHTML="<h1>Fin del juego. "+ganadores+"</h1>"
}
function mostrarPuntos(puntos2) {
	const instrucciones = document.getElementById('contenidoInstruccion');
	const puntosDiv=document.getElementById('puntos');
	if (instrucciones && !puntosDiv) {
		const puntos = document.createElement('div');
		puntos.id = 'puntos';
		puntos.innerText=puntos2
		// instrucciones.appendChild(puntos)
		instrucciones.parentNode.insertBefore(puntos, instrucciones);
	}else{
		puntosDiv.innerText=puntos2
	}
}

function seleccionarCartaBaraja(elemento) {
	console.log('seleccionar: ' + elemento);

	cartaSeleccionada = elemento;

	elemento.classList.add('seleccionada');

	console.log(elemento.innerHTML);
	socket.send(elemento.innerHTML + '.');
}

function elegirOtraCarta() {
	if (cartaSeleccionada) {
		cartaSeleccionada.classList.remove('seleccionada');
	}

	cartaSeleccionada = null;

	cargarInstruccion(['Elija una carta de la baraja']);
}

function accionInstruccion(accion) {
	let enviar = accion + '.';
	socket.send(enviar);
	if (accion == 'm') {
		const div = document.getElementById('contenidoInstruccion');
		div.removeChild(div.children[0]);
		div.removeChild(div.children[0]);
		deshabilitarCartasDisponibles();
	}
}

/* =========================
   DATOS DE EJEMPLO
   ========================= */

window.onload = function () {
	// cargarTurno('tu turno');
	// cargarCartasDisponibles(['oro-5', 'copa-7', 'espada-1', 'basto-12']);
	// cargarCartasBaraja(['oro-3', 'espada-6', 'copa-10']);
	// cargarInstruccion(['Elija una carta de la baraja']);
};
let nombreJugador = null;

function unirsePartida() {
	const input = document.getElementById('nombreJugadorInput');

	const nombre = input.value.trim();

	if (nombre === '') {
		alert('Debe ingresar un nombre.');

		return;
	}

	nombreJugador = nombre;

	if (socket.readyState !== WebSocket.OPEN) {
		alert('No hay conexión con el servidor.');
		return;
	}

	nombreJugador = nombre;

	let unirseText = 'join(' + nombre + ').';
	socket.send(unirseText);
}
function esperarInicio() {
	document.getElementById('nombreJugadorMostrado').textContent =
		nombreJugador;

	document.getElementById('panelIngreso').style.display = 'none';

	document.getElementById('panelIngreso').style.display = 'none';
	document.getElementById('contenidoJuego').style.display = 'block';
	cargarTurno('Esperando jugadores');
}

const inputCodigo = document.getElementById('nombreJugadorInput');

// 2. Escuchamos el evento 'keydown' (tecla presionada)
inputCodigo.addEventListener('keydown', function (event) {
	// 3. Verificamos si la tecla presionada es 'Enter'
	if (event.key === 'Enter') {
		event.preventDefault(); // Evita que la página se recargue si está dentro de un <form>
		unirsePartida(); // Ejecutamos tu función
	}
});
