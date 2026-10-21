# Defecto: diálogo de cobro de secretaría

Hallado en el recorrido E2E del sprint (emulador, backend local): al tocar 'Cobrar', el
TextEditingController del efectivo se liberaba al regresar showDialog, mientras el diálogo
seguía animando su salida -> 'A TextEditingController was used after being disposed',
'RenderFlex overflowed by ~99 000 pixels' y GlobalKeys duplicadas. El cobro sí llegaba al servidor.

## Antes del arreglo (develop, test/secretaria_cobro_dialogo_test.dart)
A TextEditingController was used after being disposed.
A RenderFlex overflowed by 99652 pixels on the bottom.
00:03 +0 -1: cobrar en efectivo cierra el diálogo sin errores y cobra una vez [E]
00:03 +0 -2: cancelar el cobro no llama al servidor ni deja errores [E]
00:04 +0 -3: efectivo insuficiente avisa y no cobra [E]
00:04 +0 -3: Some tests failed.

## Después del arreglo
00:03 +3: All tests passed!

## Suite completa
00:16 +99: All tests passed!
Cobertura: 2129/3679 = 57.87%
No issues found! (ran in 3.6s)
