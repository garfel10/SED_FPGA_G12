library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Top_Game_TB is
-- La entidad del testbench siempre está vacía
end Top_Game_TB;

architecture Behavioral of Top_Game_TB is

    -- Declaración del Componente 
    component Top_Game is
        Port ( 
            CLK100MHZ : in STD_LOGIC;
            CPU_RESETN : in STD_LOGIC; -- Reset Activo a nivel BAJO
            BTNU : in STD_LOGIC;
            BTND : in STD_LOGIC;
            AN : out STD_LOGIC_VECTOR (7 downto 0);
            CA : out STD_LOGIC_VECTOR (6 downto 0);
            LED : out STD_LOGIC_VECTOR (15 downto 0)
        );
    end component;

    -- Señales internas para conectar al componente
    signal clk : STD_LOGIC := '0';
    signal resetn : STD_LOGIC := '0'; -- Empezamos con reset activo (0)
    signal btnu : STD_LOGIC := '0';
    signal btnd : STD_LOGIC := '0';
    
    -- Señales de salida (para observar en la gráfica)
    signal an : STD_LOGIC_VECTOR (7 downto 0);
    signal ca : STD_LOGIC_VECTOR (6 downto 0);
    signal led : STD_LOGIC_VECTOR (15 downto 0);

    -- Definición del periodo de reloj (100 MHz -> 10 ns)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instancia de la Unidad Bajo Prueba (UUT)
    uut: Top_Game
    port map (
        CLK100MHZ => clk,
        CPU_RESETN => resetn,
        BTNU => btnu,
        BTND => btnd,
        AN => an,
        CA => ca,
        LED => led
    );

    -- Generador de Reloj
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Proceso de Estímulos 
    stim_proc: process
    begin
        -- 1. RESET DEL SISTEMA
        -- Mantenemos el reset pulsado (nivel bajo) un momento
        resetn <= '0'; 
        wait for 200 ns;
        -- Soltamos el reset (nivel alto) -> El sistema arranca
        resetn <= '1'; 
        wait for 200 ns;

        -- 2. INICIAR JUEGO (Pulsar BTNU)
        -- IMPORTANTE: Mantenemos pulsado 25ms para superar el filtro del Debouncer
        btnu <= '1';
        wait for 25 ms;  
        btnu <= '0';
        
        -- Esperamos un poco para ver si reaccionan los LEDs (Estado START -> PLAY)
        wait for 20 ms;

        -- 3. MOVER JUGADOR ARRIBA (Pulsar BTNU otra vez)
        btnu <= '1';
        wait for 25 ms; -- Otra pulsación larga
        btnu <= '0';

        -- Dejamos correr el reloj para ver el refresco de los displays
        wait for 20 ms;

        -- 4. MOVER JUGADOR ABAJO (Pulsar BTND)
        btnd <= '1';
        wait for 25 ms; 
        btnd <= '0';

        wait; -- Fin de la simulación
    end process;

end Behavioral;
