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
    
    -- PUNTOS PARA PASAR NIVEL (5 para probar rápido)
    constant POINTS_PER_LEVEL : integer := 1; 
    
    signal spawn_timer : integer range 0 to 20 := 0; 
    signal win_timer : integer range 0 to 20 := 0;
    
    -- RECUPERADO: Señal para el parpadeo de LEDs
    signal blink_toggle : std_logic := '0';

    signal display_buffer : std_logic_vector(63 downto 0);

    signal btn_up_prev   : std_logic := '0';
    signal btn_down_prev : std_logic := '0';
    signal pulse_up      : std_logic := '0';
    signal pulse_down    : std_logic := '0';

begin

    -- PROCESO PRINCIPAL
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
            blink_toggle <= '0';
            
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

            -- Máquina de Estados (Lógica de transición inmediata)
            if current_state = STATE_START then
                if pulse_up = '1' then
                    current_state <= STATE_PLAY;
                    lives <= 3;
                    player_x <= 6;
                    lane_top <= (others => '0');
                    lane_middle <= (others => '0');
                    lane_bottom <= (others => '0');
                    score_counter <= 0;
                end if;
            end if;

            -- Lógica sincronizada con el juego (Tick)
            if game_tick = '1' then
                case current_state is
                    when STATE_START => 
                        blink_toggle <= '0'; -- Resetear parpadeo

                    when STATE_PLAY =>
                        -- Mover obstáculos
                        lane_top    <= lane_top(6 downto 0) & '0';
                        lane_middle <= lane_middle(6 downto 0) & '0';
                        lane_bottom <= lane_bottom(6 downto 0) & '0';
                        
                        -- Generar obstáculo (con cadencia)
                        if spawn_timer = 0 then
                            spawn_timer <= 4; 
                            case rnd_in(1 downto 0) is
                                when "00" => lane_top(0) <= '1';
                                when "01" => lane_middle(0) <= '1';
                                when "10" => lane_bottom(0) <= '1';
                                when others => null;
                            end case;
                        else
                            spawn_timer <= spawn_timer - 1;
                        end if;

                        -- Colisiones
                        if (player_y = 2 and lane_top(player_x) = '1') or
                           (player_y = 1 and lane_middle(player_x) = '1') or
                           (player_y = 0 and lane_bottom(player_x) = '1') then
                            
                            if lives > 0 then
                                lives <= lives - 1;
                            else
                                current_state <= STATE_GAMEOVER;
                            end if;
                            
                            if player_y = 2 then lane_top(player_x) <= '0'; end if;
                            if player_y = 1 then lane_middle(player_x) <= '0'; end if;
                            if player_y = 0 then lane_bottom(player_x) <= '0'; end if;

                        else
                            -- Puntuación Inteligente (Solo obstáculos reales)
                            if (lane_top(player_x) = '1') or 
                               (lane_middle(player_x) = '1') or 
                               (lane_bottom(player_x) = '1') then
                                
                                score_counter <= score_counter + 1;
                                
                                if score_counter >= (POINTS_PER_LEVEL - 1) then
                                    score_counter <= 0;
                                    current_state <= STATE_LEVEL_WIN;
                                    win_timer <= 0;
                                end if;
                            end if;
                        end if;

                   
                    
                    when STATE_LEVEL_WIN =>
                        -- Freno (Prescaler): Si subes el 10, va más lento. Si lo bajas, más rápido.
                        -- Como hemos cambiado el rango a 20, ahora sí cabe el 10.
                        if spawn_timer < 5 then 
                            spawn_timer <= spawn_timer + 1;
                        else
                            -- Ha pasado el tiempo de espera, avanzamos un paso la animación
                            spawn_timer <= 0; -- Reset del freno
                            
                            win_timer <= win_timer + 1;
                            blink_toggle <= not blink_toggle; 
                            
                            if win_timer >= 4 then -- Duración de la victoria
                                win_timer <= 0; -- IMPORTANTE: Limpiar timer para el futuro
                                blink_toggle <= '0'; -- Apagar parpadeo al salir
                                
                                if player_x > 0 then
                                    player_x <= player_x - 1; -- Avanzar Nivel
                                    current_state <= STATE_PLAY;
                                    spawn_timer <= 0; -- Asegurar que empezamos disparando
                                else
                                    current_state <= STATE_GAME_WON; -- Ganar Juego
                                end if;
                            end if;
                        end if;
                    
                    when STATE_GAME_WON =>
                         -- Esperamos al botón START (BTNC) para reiniciar todo
                         if pulse_up = '1' then
                            current_state <= STATE_START;
                         end if;
                         
                    when STATE_GAMEOVER =>
                         if pulse_up = '1' then current_state <= STATE_START; end if;
                end case;
            end if;
        end if;
    end process;

    -- PROCESO DE DIBUJADO (DISPLAYS)
    process(player_y, lives, lane_top, lane_middle, lane_bottom, current_state, player_x)
        variable char_map : std_logic_vector(7 downto 0);
    begin
        display_buffer <= (others => '0'); 
        if current_state = STATE_START or current_state = STATE_PLAY or current_state = STATE_LEVEL_WIN then   
        -- Vidas
            case lives is
                when 3 => display_buffer(63 downto 56) <= "01001111"; 
                when 2 => display_buffer(63 downto 56) <= "01011011"; 
                when 1 => display_buffer(63 downto 56) <= "00000110"; 
                when others => display_buffer(63 downto 56) <= "00111111"; 
            end case;

        -- Juego
            for i in 0 to 6 loop
                char_map := "00000000"; 
                if lane_top(i) = '1'    then char_map(0) := '1'; end if;
                if lane_middle(i) = '1' then char_map(6) := '1'; end if;
                if lane_bottom(i) = '1' then char_map(3) := '1'; end if;
            
                if i = player_x then
                    if current_state = STATE_PLAY or current_state = STATE_START or current_state = STATE_LEVEL_WIN then
                        if player_y = 2 then char_map(0) := '1'; end if;
                        if player_y = 1 then char_map(6) := '1'; end if;
                        if player_y = 0 then char_map(3) := '1'; end if;
                    end if;
                end if;
                display_buffer((i*8)+7 downto (i*8)) <= char_map;
            end loop;
        
        -- CASO 2: GAME OVER (Texto "PERDISTE")
        elsif current_state = STATE_GAMEOVER then
             -- Mapeo manual de letras (A=0 ... G=6)
             display_buffer(63 downto 56) <= "01110011"; -- P (Display 7)
             display_buffer(55 downto 48) <= "01111001"; -- E
             display_buffer(47 downto 40) <= "01010000"; -- r
             display_buffer(39 downto 32) <= "01011110"; -- d
             display_buffer(31 downto 24) <= "00000110"; -- I (usamos un 1)
             display_buffer(23 downto 16) <= "01101101"; -- S
             display_buffer(15 downto 8)  <= "01111000"; -- t
             display_buffer(7 downto 0)   <= "01111001"; -- E (Display 0)

        -- CASO 3: GANADOR (Texto "GANADOR ")
        elsif current_state = STATE_GAME_WON then
             display_buffer(63 downto 56) <= "00111101"; -- G (Display 7)
             display_buffer(55 downto 48) <= "01110111"; -- A
             display_buffer(47 downto 40) <= "00110111"; -- n (mira a la izq)
             display_buffer(39 downto 32) <= "01110111"; -- A
             display_buffer(31 downto 24) <= "01011110"; -- d
             display_buffer(23 downto 16) <= "00111111"; -- O
             display_buffer(15 downto 8)  <= "01010000"; -- r
             display_buffer(7 downto 0)   <= "00000000"; -- (Espacio vacío)
        end if;
        
    end process;

    segments_out <= display_buffer;
    
    -- PROCESO DE SALIDA DE LEDS (PARPADEO RESTAURADO)
    process(current_state, blink_toggle)
    begin
        leds_out <= (others => '0'); -- Por defecto apagados
        
        if current_state = STATE_START then
            leds_out(0) <= '1'; -- LED 0 indica espera
        elsif current_state = STATE_PLAY then
            leds_out(1) <= '1'; -- LED 1 indica jugando
        elsif current_state = STATE_LEVEL_WIN then
            -- Si blink_toggle es 1, encendemos TODOS. Si es 0, apagamos TODOS.
            leds_out <= (others => blink_toggle); 
        elsif current_state = STATE_GAME_WON then
             leds_out <= (others => '1');   
        elsif current_state = STATE_GAMEOVER then
             leds_out <= "1010101010101010"; -- Patrón fijo de derrota
             
        end if;
    end process;

end Behavioral;