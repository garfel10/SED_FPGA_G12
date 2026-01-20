library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Clock_Divider is
    Port (
        clk_100MHz : in  STD_LOGIC; -- Reloj base del sistema (oscilador de la Nexys A7)
        reset      : in  STD_LOGIC; -- Botón de reset global (activo alto)
        clk_disp   : out STD_LOGIC; -- Salida de reloj lento para multiplexar los displays (~1 kHz)
        game_tick  : out STD_LOGIC  -- Salida de pulso (tick) para controlar la velocidad del juego
    );
end Clock_Divider;

architecture Behavioral of Clock_Divider is
    --  CONFIGURACIÓN DE FRECUENCIAS
    
    -- Constante para el refresco de displays.
    -- Calcula el límite de cuenta para dividir los 100 MHz a una frecuencia visible.
    constant DISP_LIMIT : integer := 100000;
    
    -- Constante para la velocidad del juego.
    -- Determina cada cuántos ciclos de reloj se mueve un obstáculo.
    -- Un valor más alto = juego más lento. Un valor más bajo = juego más rápido.
    constant GAME_LIMIT : integer := 10000000; 

    -- NOTA: Valores reducidos para simulación (Descomentar solo para testbench):
    -- constant DISP_LIMIT : integer := 5; 
    -- constant GAME_LIMIT : integer := 10;

    --  SEÑALES INTERNAS (CONTADORES Y REGISTROS) 
    
    -- Señales para la lógica del Display
    signal ctr_disp : integer range 0 to DISP_LIMIT := 0; -- Contador acumulativo
    signal reg_disp : std_logic := '0';                   -- Registro que almacena el estado alto/bajo
    
    -- Señales para la lógica del Juego
    signal ctr_game : integer range 0 to GAME_LIMIT := 0; -- Contador acumulativo
    signal reg_game : std_logic := '0';                   -- Registro para el pulso de salida

begin

    -- Proceso secuencial síncrono sensible al reloj y al reset
    process(clk_100MHz, reset)
    begin
        -- Reinicio asíncrono: pone todo a cero si se pulsa Reset
        if reset = '1' then
            ctr_disp <= 0;
            reg_disp <= '0';
            ctr_game <= 0;
            reg_game <= '0';
            
        -- Lógica síncrona: se ejecuta en cada flanco de subida del reloj
        elsif rising_edge(clk_100MHz) then
            
         
            -- 1. GENERACIÓN DEL RELOJ DE DISPLAY (Onda Cuadrada)
         
            -- Este bloque genera una señal con ciclo de trabajo del 50%
            if ctr_disp = DISP_LIMIT - 1 then
                ctr_disp <= 0;            -- Reiniciamos la cuenta
                reg_disp <= not reg_disp; -- Invertimos la señal (Toggle: de 0 a 1, o de 1 a 0)
            else
                ctr_disp <= ctr_disp + 1; -- Incrementamos cuenta
            end if;
            
        
            -- 2. GENERACIÓN DEL TICK DE JUEGO (Pulso Enable)
            
            -- Este bloque genera un pulso que dura EXACTAMENTE 1 ciclo de reloj.
           
            if ctr_game = GAME_LIMIT - 1 then
                ctr_game <= 0;
                reg_game <= '1'; -- ¡Disparo! Activamos la señal de movimiento
            else
                ctr_game <= ctr_game + 1;
                reg_game <= '0'; -- Mantenemos apagada la señal el resto del tiempo
            end if;
            
        end if;
    end process;

    -- Asignación de las señales internas a los puertos de salida
    clk_disp <= reg_disp;
    game_tick <= reg_game;

end Behavioral;