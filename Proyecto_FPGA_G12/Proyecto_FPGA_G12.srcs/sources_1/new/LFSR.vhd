library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LFSR is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        rnd_out  : out STD_LOGIC_VECTOR (7 downto 0) -- Salida de 8 bits con el número aleatorio
    );
end LFSR;

architecture Behavioral of LFSR is
    -- Registro interno que guarda el número actual.
    -- Es vital darle un valor inicial (Semilla) que NO sea todo ceros,
    -- porque si empieza en 00000000 se queda atascado ahí para siempre.
    signal lfsr_reg : std_logic_vector(7 downto 0) := "10101010"; 
begin

    process(clk, reset)
        variable feedback : std_logic; -- Variable auxiliar para calcular el nuevo bit
    begin
        if reset = '1' then
            lfsr_reg <= "10101010"; -- Si pulsamos reset, volvemos al valor inicial
        elsif rising_edge(clk) then
            -- Calculamos el "Feedback" (el nuevo bit que vamos a meter).
            -- Usamos compuertas XOR combinando varios bits del registro actual.
            -- Esta combinación específica hace que los números parezcan aleatorios y no se repitan rápido.
            feedback := lfsr_reg(7) xor lfsr_reg(5) xor lfsr_reg(4) xor lfsr_reg(3);
            
            -- Actualizamos el registro:
            -- 1. Desplazamos todos los bits una posición a la izquierda (lfsr_reg(6 downto 0)).
            -- 2. Insertamos el bit calculado (feedback) en la posición vacía de la derecha (& feedback).
            lfsr_reg <= lfsr_reg(6 downto 0) & feedback;
        end if;
    end process;

    -- Conectamos el registro interno a la salida del componente
    rnd_out <= lfsr_reg;

end Behavioral;