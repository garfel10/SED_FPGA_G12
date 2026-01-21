library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Game_Logic_TB is
end Game_Logic_TB;

architecture Behavioral of Game_Logic_TB is

    
    component Game_Logic is
        Port (
            clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;
            game_tick    : in  STD_LOGIC;
            btn_up       : in  STD_LOGIC;
            btn_down     : in  STD_LOGIC;
            rnd_in       : in  STD_LOGIC_VECTOR (7 downto 0);
            
            segments_out : out STD_LOGIC_VECTOR (63 downto 0);
            leds_out     : out STD_LOGIC_VECTOR (15 downto 0)
        );
    end component;

    -- SEÑALES
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal game_tick : std_logic := '0';
    signal btn_up : std_logic := '0';
    signal btn_down : std_logic := '0';
    
    -- TRUCO: Ponemos esto a 0 para que salgan enemigos en el carril TOP y choquemos
    signal rnd_in : std_logic_vector(7 downto 0) := "00000000"; 
    
    -- Salidas
    signal segments_out : std_logic_vector(63 downto 0);
    signal leds_out : std_logic_vector(15 downto 0);

    constant clk_period : time := 10 ns;

begin

    -- CONEXIÓN (PORT MAP)
    uut: Game_Logic port map (
        clk => clk,
        reset => reset,
        game_tick => game_tick,
        btn_up => btn_up,
        btn_down => btn_down,
        rnd_in => rnd_in,
        segments_out => segments_out,
        leds_out => leds_out
    );

    -- RELOJ
    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- PROCESO DE PRUEBA (ESTÍMULOS)
    stim_proc: process
    begin
        -- 1. RESET INICIAL
        reset <= '1'; wait for 50 ns;
        reset <= '0'; wait for 50 ns;

        -- 2. INICIAR JUEGO 
        wait for 100 ns;
        btn_up <= '1'; 
        wait for 20 ns; -- Un pulso corto
        btn_up <= '0';
        wait for 100 ns;

        -- 3. SIMULAR EL PASO DEL TIEMPO (Ticks del juego)
        -- Hacemos ticks para que el obstáculo avance hacia nosotros
        for i in 0 to 30 loop
            game_tick <= '1'; wait for clk_period; 
            game_tick <= '0'; wait for 200 ns; -- Espera entre ticks
        end loop;
        
        -- 4. PROVOCAR COLISIÓN 
        -- Como rnd_in es 0, el obstáculo viene por ARRIBA (Lane Top).
        -- Para chocar, tenemos que subir al jugador a la posición de arriba (player_y = 2).
        -- El jugador empieza en medio (1), así que pulsamos ARRIBA una vez.
        
        btn_up <= '1'; wait for 20 ns;
        btn_up <= '0';
        
        -- Dejamos pasar más tiempo para que el obstáculo nos golpee
        for i in 0 to 10 loop
            game_tick <= '1'; wait for clk_period; 
            game_tick <= '0'; wait for 200 ns;
        end loop;

        wait; -- Fin de la simulación
    end process;

end Behavioral;