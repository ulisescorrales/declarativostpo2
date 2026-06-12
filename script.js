let cartaSeleccionada = null;

/* =========================
   TURNO
   ========================= */

function cargarTurno(nombreJugador) {
  document.getElementById("turnoJugador").textContent = nombreJugador;

  if (nombreJugador !== "tu turno") {
    cargarInstruccion(["espere su turno"]);
  } else {
    cargarInstruccion(["Elija una carta de la baraja"]);
  }
}
/* =========================
   INSTRUCCIONES
   ========================= */

function cargarInstruccion(instrucciones) {
  const contenedor = document.getElementById("contenidoInstruccion");

  contenedor.innerHTML = "";

  if (instrucciones.length === 1 && instrucciones[0] === "espere su turno") {
    document.body.classList.add("turno-espera");
  } else {
    document.body.classList.remove("turno-espera");
  }

  if (instrucciones.length === 1) {
    contenedor.textContent = instrucciones[0];
  } else {
    instrucciones.forEach((texto) => {
      const boton = document.createElement("button");

      boton.textContent = texto;

      boton.onclick = function () {
        accionInstruccion(texto);
      };

      contenedor.appendChild(boton);
    });
  }
}
/* =========================
   CARTAS DISPONIBLES
   ========================= */

function cargarCartasDisponibles(listaCartas) {
  const contenedor = document.getElementById("cartasDisponibles");

  contenedor.innerHTML = "";

  listaCartas.forEach((nombre) => {
    const carta = document.createElement("div");

    carta.className = "carta carta-disponible";

    carta.textContent = nombre;

    contenedor.appendChild(carta);
  });
}

/* =========================
   BARAJA DEL JUGADOR
   ========================= */

function cargarCartasBaraja(listaCartas) {
  const contenedor = document.getElementById("barajaJugador");

  contenedor.innerHTML = "";

  listaCartas.forEach((nombre) => {
    const carta = document.createElement("div");

    carta.className = "carta carta-baraja";

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

function seleccionarCartaBaraja(elemento) {
  if (cartaSeleccionada !== null) {
    return;
  }

  cartaSeleccionada = elemento;

  elemento.classList.add("seleccionada");

  cargarInstruccion([
    "Tirar",
    "Combinar con cartas disponibles",
    "Elegir otra carta de la baraja",
  ]);
}

function elegirOtraCarta() {
  if (cartaSeleccionada) {
    cartaSeleccionada.classList.remove("seleccionada");
  }

  cartaSeleccionada = null;

  cargarInstruccion(["Elija una carta de la baraja"]);
}

function accionInstruccion(accion) {
  switch (accion) {
    case "Tirar":
      alert("Tirar carta: " + cartaSeleccionada.textContent);

      break;

    case "Combinar con cartas disponibles":
      alert("Combinar carta: " + cartaSeleccionada.textContent);

      break;

    case "Elegir otra carta de la baraja":
      elegirOtraCarta();

      break;
  }
}

/* =========================
   DATOS DE EJEMPLO
   ========================= */

window.onload = function () {
  cargarTurno("tu turno");

  cargarCartasDisponibles(["oro-5", "copa-7", "espada-1", "basto-12"]);

  cargarCartasBaraja(["oro-3", "espada-6", "copa-10"]);

  cargarInstruccion(["Elija una carta de la baraja"]);
};
let nombreJugador = null;

function unirsePartida() {
  const input = document.getElementById("nombreJugadorInput");

  const nombre = input.value.trim();

  if (nombre === "") {
    alert("Debe ingresar un nombre.");

    return;
  }

  nombreJugador = nombre;

  document.getElementById("nombreJugadorMostrado").textContent = nombreJugador;

  document.getElementById("panelIngreso").style.display = "none";

  document.getElementById("contenidoJuego").style.display = "block";

  console.log("Jugador unido:", nombreJugador);
}


const socket = new WebSocket("ws://localhost:8316/ws");

// Connection opened
socket.addEventListener("open", (event) => {
  socket.send("Hello Server!");
  console.log("Send");
});

// Listen for messages
socket.addEventListener("message", (event) => {
  console.log("Message from server ", event.data);
});
socket.addEventListener("error", (event) => {
  console.log("Error WebSocket", event.data);
});
