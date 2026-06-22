:- use_module(library(js)).
:- use_module(library(dom)).

seq_opcion([E]) --> [E],
{
	char_code('\n',Code),
	E \= 10
}.
seq_opcion([E|Es]) --> [E], {
	char_code('\n',Code),
	E \= 10
},seq_opcion(Es).

opciones([Opcion]) -->seq_opcion(Opcion).
opciones([Opcion|Resto])-->seq_opcion(Opcion),`\n`,opciones(Resto).
mensaje_opciones(Opciones) -->`Eliga una opcion (responda solo con la letra):\n`,opciones(Opciones).

seq([E]) --> [E].
seq([E|Es]) --> [E], {
	char_code(',',Code),
	E \= Code
},seq(Es).

turno(Jugador) --> `turno de: `,seq(Jugador).

cartas([Carta])-->seq(Carta).
cartas([Carta|Resto])-->seq(Carta),`,`,cartas(Resto).
% mensaje_cartas(Cartas) -->`Cartas en la mesa disponibles: [`,cartas(Cartas).
mensaje_cartas(Cartas) -->`cartas en la mesa disponibles: [`,cartas(Cartas),`]`,([];`\n`).
mensaje_cartas_turno(Cartas) -->`Eliga carta en la mesa para combinar (indique palo-numero): [`,cartas(Cartas),`]`.

mensaje_baraja(Cartas) -->`tu turno: [`,cartas(Cartas),`]`.
mensaje_baraja2(Cartas) -->`su baraja: [`,cartas(Cartas),`]`.
mensaje_baraja2([]) -->`su baraja: []`.

mensaje_elegida(Carta) -->`Carta elegida: `,seq(Carta).

... --> [].
... --> [_],... .
mensaje_ganadores-->`Ganadores`, ... .

mensaje_agarrar --> ... , `agarrar cartas de la mesa`.

mensaje_suma -->`Cartas elegidas suman`,... .

imprimirLista([]).
imprimirLista([H|T]):-
	string_codes(String,H),
	format("~w~n",[String]),
	imprimirLista(T).

convertir_lista_a_atomos([],[]).
convertir_lista_a_atomos([H|T],[H2|T2]):-
	atom_chars(H2,H),
	convertir_lista_a_atomos(T,T2).

procesar_mensaje(Message) :-
	(
		%Habilitar agarrar cartas de la mesa
		atom_chars(Message,Chars6),
		phrase(mensaje_agarrar,Chars6),
		prop(habilitarCartasDisponibles,Habilitar),
		apply(Habilitar,[],_);

		%Recibir ganadores
		atom_chars(Message,Chars5),
		phrase(mensaje_ganadores,Chars5),
		prop(informarGanadores,Instrucciones),
		apply(Instrucciones,[Message],_)
		;
		%Recibir opciones
		atom_chars(Message,Chars4),
		phrase(mensaje_opciones(Opciones),Chars4),
		convertir_lista_a_atomos(Opciones,OpcionesAtom),
		prop(cargarInstruccion2,Instrucciones),
		apply(Instrucciones,OpcionesAtom,_);

		%Carta elegida
		atom_chars(Message,Chars3),
		phrase(mensaje_elegida(Carta),Chars3),
		prop(pintarSeleccionBaraja,Seleccionar),
		atom_chars(CartaAtom,Carta),
		apply(Seleccionar,[CartaAtom],_)

	;
		%Cartas Baraja
		atom_chars(Message,Chars2),
		phrase(mensaje_baraja(Cartas2),Chars2),
		convertir_lista_a_atomos(Cartas2,Cartas3),
		prop(cargarCartasBaraja,CartasBaraja),
		apply(CartasBaraja,Cartas3,_),
		prop(cargarTurno,Turno),
		apply(Turno,['tu turno'],_)
	;
		%recibir barajas
		atom_chars(Message,Chars2),
		phrase(mensaje_baraja2(Cartas2),Chars2),
		convertir_lista_a_atomos(Cartas2,Cartas3),
		prop(cargarCartasBaraja,CartasBaraja),
		apply(CartasBaraja,Cartas3,_)
	;
		%mensaje de puntos
		atom_chars(Message,Chars2),
		phrase(mensaje_suma,Chars2),
		prop(mostrarPuntos,Puntos),
		apply(Puntos,[Message],_)
	;

		Message == 'elegir';
		Message=='conectado correctamente'->
		prop(esperarInicio,Esperar),
		apply(Esperar,[],Value);

		Message=='esperando más players'->
		prop(cargarInstruccion,Instruccion),
		apply(Instruccion,[[Message]],Value);
		%Turno jugador
		atom_chars(Message,Chars),
		phrase(turno(Jug),Chars),
		atom_chars(Jugador,Jug),
		prop(cargarTurno,Turno),
		apply(Turno,[Jugador],Value);
		%Cartas disponibles
		atom_chars(Message,Chars),
		phrase(mensaje_cartas(Cartas),Chars),
		convertir_lista_a_atomos(Cartas,Cartas2),
		prop(cargarCartasDisponibles,CartasDisponibles),
		apply(CartasDisponibles,Cartas2,_)
		% prop(deshabilitarCartasDisponibles,Deshabilitar),
		% apply(Deshabilitar,[],_)
	;
		%cartas disponibles para el turno
		atom_chars(Message,Chars),
		phrase(mensaje_cartas_turno(Cartas),Chars),
		convertir_lista_a_atomos(Cartas,Cartas2),
		prop(cargarCartasDisponiblesTurno,CartasDisponibles),
		apply(CartasDisponibles,Cartas2,_)
		% prop(habilitarCartasDisponibles,habilitar),
		% apply(habilitar,[],_)
	;

		atom_chars(Message,Chars),
		phrase(mensaje_suma,Chars),
		prop(cargarInstruccion,Instruccion),
		apply(Instruccion,[[Message]],Value)

		% ;
		% Message=='tu turno'->
		% prop(cargarTurno,Turno),
		% apply(Turno,[Message],_)
	)
	.

escribir_salida(Message):-
    % 1. Buscamos el elemento input mediante su ID
    get_by_id('pl', Out),
    % 2. Le asignamos el texto 'hola' a su propiedad 'value'
	html(Out,Message)
	% get_window(W)
	.
