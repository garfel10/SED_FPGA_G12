library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Game_Logic is
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
end Game_Logic;

architecture Behavioral of Game_Logic is

    type state_type is (STATE_START, STATE_PLAY, STATE_LEVEL_WIN, STATE_GAMEOVER, STATE_GAME_WON);
    signal current_state : state_type := STATE_START;

    signal player_y : integer range 0 to 2 := 1;
    signal player_x : integer range 0 to 7 := 6; 
    signal lives : integer range 0 to 3 := 3;

    signal lane_top    : std_logic_vector(7 downto 0) := (others => '0');
    signal lane_middle : std_logic_vector(7 downto 0) := (others => '0');
    signal lane_bottom : std_logic_vector(7 downto 0) := (others => '0');

    signal score_counter : integer := 0;
    
    -- Configuración básica (TODO: Ajustar dificultad más adelante)
    constant POINTS_PER_LEVEL : integer := 5; 
    
    signal spawn_timer : integer range 0 to 20 := 0; 
    signal win_timer : integer range 0 to 20 := 0;
    
    signal display_buffer : std_logic_vector(63 downto 0);

    signal btn_up_prev   : std_logic := '0';
    signal btn_down_prev : std_logic := '0';
    signal pulse_up      : std_logic := '0';
    signal pulse_down    : std_logic := '0';

begin

    -- PROCESO PRINCIPAL: Control de flujo y movimiento básico
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= STATE_START;
            player_y <= 1;
            player_x <= 6; 
            lives <= 3;
            lane_top <= (others => '0');
            lane_middle <= (others => '0');
            lane_bottom <= (others => '0');
            score_counter <= 0;
            spawn_timer <= 0;
            btn_up_prev <= '0';
            btn_down_prev <= '0';
            
        elsif rising_edge(clk) then
            
            -- Detector de flancos (Botones)
            pulse_up <= '0';
            pulse_down <= '0';
            if btn_up = '1' and btn_up_prev = '0' then pulse_up <= '1'; end if;
            if btn_down = '1' and btn_down_prev = '0' then pulse_down <= '1'; end if;
            btn_up_prev <= btn_up;
            btn_down_prev <= btn_down;

            -- Movimiento Jugador
            if pulse_up = '1' and player_y < 2 then player_y <= player_y + 1;
            elsif pulse_down = '1' and player_y > 0 then player_y <= player_y - 1;
            end if;

            -- Máquina de Estados Básica
            if current_state = STATE_START then
                if pulse_up = '1' then
                    current_state <= STATE_PLAY;
                    lives <= 3;
                    -- TODO: Resetear resto de variables de juego aquí
                end if;
            end if;

            -- Lógica sincronizada con el juego (Tick)
            if game_tick = '1' then
                case current_state is
                    when STATE_START => 
                        null;

                    when STATE_PLAY =>
                        -- Mover obstáculos (Desplazamiento simple)
                        lane_top    <= lane_top(6 downto 0) & '0';
                        lane_middle <= lane_middle(6 downto 0) & '0';
                        lane_bottom <= lane_bottom(6 downto 0) & '0';
                        
                        -- TODO: Implementar lógica de generación aleatoria con rnd_in
                        -- Por ahora solo desplazamos ceros.
                        
                        -- TODO: Implementar detección de COLISIONES
                        -- TODO: Implementar sistema de PUNTUACIÓN y VICTORIA
                    
                    when STATE_LEVEL_WIN =>
                        -- Pendiente de implementar animación
                        current_state <= STATE_PLAY; 

                    when STATE_GAME_WON =>
                        -- Pendiente
                         if pulse_up = '1' then current_state <= STATE_START; end if;
                         
                    when STATE_GAMEOVER =>
                         if pulse_up = '1' then current_state <= STATE_START; end if;
                end case;
            end if;
        end if;
    end process;

    -- PROCESO DE DIBUJADO (DISPLAYS)
    -- Versión preliminar: Solo dibuja carriles y jugador. Falta texto.
    process(player_y, lives, lane_top, lane_middle, lane_bottom, current_state, player_x)
        variable char_map : std_logic_vector(7 downto 0);
    begin
        display_buffer <= (others => '0'); 
        
        -- Dibujado de vidas (Simple)
        case lives is
            when 3 => display_buffer(63 downto 56) <= "01001111"; 
            when 2 => display_buffer(63 downto 56) <= "01011011"; 
            when 1 => display_buffer(63 downto 56) <= "00000110"; 
            when others => display_buffer(63 downto 56) <= "00111111"; 
        end case;

        -- Dibujado de Carriles y Jugador
        for i in 0 to 6 loop
            char_map := "00000000"; 
            if lane_top(i) = '1'    then char_map(0) := '1'; end if;
            if lane_middle(i) = '1' then char_map(6) := '1'; end if;
            if lane_bottom(i) = '1' then char_map(3) := '1'; end if;
            
            if i = player_x then
                if player_y = 2 then char_map(0) := '1'; end if;
                if player_y = 1 then char_map(6) := '1'; end if;
                if player_y = 0 then char_map(3) := '1'; end if;
            end if;
            display_buffer((i*8)+7 downto (i*8)) <= char_map;
        end loop;
        
        -- TODO: Añadir mapeo de letras para GAME OVER y WIN
        
    end process;

    segments_out <= display_buffer;
    
    -- PROCESO DE SALIDA DE LEDS (Debug estados)
    process(current_state)
    begin
        leds_out <= (others => '0'); 
        
        if current_state = STATE_START then
            leds_out(0) <= '1';
        elsif current_state = STATE_PLAY then
            leds_out(1) <= '1';
        elsif current_state = STATE_GAMEOVER then
            leds_out <= (others => '1'); -- Encender todos al perder (Test)
        end if;
    end process;

end Behavioral;