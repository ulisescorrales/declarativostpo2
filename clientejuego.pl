%prolog
%El cliente lo único que hace es ser informado del estado del juego, si tiene que elegir una carta y avisarle si ganó antes de finalizar el juego
:- module(clientejuego, [main/0]).

:- use_module(library(http/websocket)).

main :-
    format("Ingresa tu nombre: "),
    read(Nombre),
    format("Conectando a ws://localhost:8316/ws~n", []),
    http_open_websocket('ws://localhost:8316/ws', WebSocket, []),
    ws_send(WebSocket, prolog(join(Nombre))),
    escuchar_mensajes(WebSocket).

escuchar_mensajes(Stream) :-
    % format("Esperando mensajes...~n", []),
    ws_receive(Stream, Message, []),
    procesar_mensaje(Stream, Message).

procesar_mensaje(Stream, Message) :-
    (   
        Message.data == "¡Juego terminado!" ->
        format("~w~n", [Message.data]),
        format("Desconectando...~n", []),
        ws_close(Stream, 1000, "Cliente terminando")
     ;   Message.opcode == close ->
         format("Conexión cerrada por el servidor~n", []),
        format("Mensaje: ~w~n", [Message.data]),
		 halt
    ;   
		Message.data =="elegir" ->
		read(Opcion),
		ws_send(Stream,prolog(Opcion)),
        escuchar_mensajes(Stream)
	;
		Message.data == end_of_file ->
		format("Error~n"),
		halt
	;
        format("Mensaje: ~w~n", [Message.data]),
        escuchar_mensajes(Stream)
    ).
