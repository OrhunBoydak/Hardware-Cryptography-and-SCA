library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity point_add is
    Generic ( WIDTH : integer := 32 );
    Port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        start      : in  std_logic;
        p1_x, p1_y : in  std_logic_vector(WIDTH-1 downto 0);
        p2_x, p2_y : in  std_logic_vector(WIDTH-1 downto 0);
        modulus    : in  std_logic_vector(WIDTH-1 downto 0);
        res_x, res_y : out std_logic_vector(WIDTH-1 downto 0);
        done       : out std_logic
    );
end point_add;

architecture Behavioral of point_add is

    ----------------------------------------------------------------
    -- COMPONENTS
    ----------------------------------------------------------------
    component mod_exp is
        Generic ( DATA_WIDTH : integer );
        Port (
            clk : in std_logic;
            rst : in std_logic;
            start : in std_logic;
            start_value : in std_logic_vector(DATA_WIDTH-1 downto 0);
            base : in std_logic_vector(DATA_WIDTH-1 downto 0);
            exp : in std_logic_vector(DATA_WIDTH-1 downto 0);
            modulus : in std_logic_vector(DATA_WIDTH-1 downto 0);
            result : out std_logic_vector(DATA_WIDTH-1 downto 0);
            done : out std_logic
        );
    end component;

    component mon_pro is
        Generic ( DATA_WIDTH : integer );
        Port (
            clk : in std_logic;
            rst : in std_logic;
            start : in std_logic;
            a_in, b_in, n_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
            result : out std_logic_vector(DATA_WIDTH-1 downto 0);
            done : out std_logic
        );
    end component;

    ----------------------------------------------------------------
    -- FSM
    ----------------------------------------------------------------
    type state_type is (
        IDLE,
        START_INV, WAIT_INV,
        START_LAMBDA, WAIT_LAMBDA,
        START_X3_SQ, WAIT_X3_SQ,
        CALC_X3,
        START_Y3, WAIT_Y3,
        FINISH
    );
    signal state : state_type;

    ----------------------------------------------------------------
    -- SIGNALS
    ----------------------------------------------------------------
    signal me_start, me_done : std_logic;
    signal mp_start, mp_done : std_logic;

    signal me_res, mp_res : std_logic_vector(WIDTH-1 downto 0);
    signal mp_a, mp_b     : std_logic_vector(WIDTH-1 downto 0);

    signal r_dx, r_dy     : std_logic_vector(WIDTH-1 downto 0);
    signal r_lambda       : std_logic_vector(WIDTH-1 downto 0);
    signal r_x3           : std_logic_vector(WIDTH-1 downto 0);
    signal r_p_minus_2    : std_logic_vector(WIDTH-1 downto 0);

    ----------------------------------------------------------------
    -- MODULAR SUBTRACTION
    ----------------------------------------------------------------
    function mod_sub(a, b, m : unsigned) return std_logic_vector is
    begin
        if a >= b then
            return std_logic_vector(a - b);
        else
            return std_logic_vector((a + m) - b);
        end if;
    end function;

begin

    ----------------------------------------------------------------
    -- p - 2 (FERMAT INVERSION)
    ----------------------------------------------------------------
    r_p_minus_2 <= std_logic_vector(unsigned(modulus) - 2);

    ----------------------------------------------------------------
    -- MODULAR INVERSE (dx^-1 mod p)
    ----------------------------------------------------------------
    U_INV : mod_exp
        generic map (DATA_WIDTH => WIDTH)
        port map (
            clk => clk,
            rst => rst,
            start => me_start,
            start_value => std_logic_vector(to_unsigned(1, WIDTH)),
            base => r_dx,
            exp => r_p_minus_2,
            modulus => modulus,
            result => me_res,
            done => me_done
        );

    ----------------------------------------------------------------
    -- MODULAR MULTIPLIER
    ----------------------------------------------------------------
    U_MULT : mon_pro
        generic map (DATA_WIDTH => WIDTH)
        port map (
            clk => clk,
            rst => rst,
            start => mp_start,
            a_in => mp_a,
            b_in => mp_b,
            n_in => modulus,
            result => mp_res,
            done => mp_done
        );

    ----------------------------------------------------------------
    -- MAIN FSM
    ----------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            done <= '0';
            me_start <= '0';
            mp_start <= '0';
            res_x <= (others => '0');
            res_y <= (others => '0');

        elsif rising_edge(clk) then
            case state is

                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        r_dx <= mod_sub(unsigned(p2_x), unsigned(p1_x), unsigned(modulus));
                        r_dy <= mod_sub(unsigned(p2_y), unsigned(p1_y), unsigned(modulus));
                        state <= START_INV;
                    end if;

                when START_INV =>
                    me_start <= '1';
                    state <= WAIT_INV;

                when WAIT_INV =>
                    me_start <= '0';
                    if me_done = '1' then
                        state <= START_LAMBDA;
                    end if;

                when START_LAMBDA =>
                    mp_a <= r_dy;
                    mp_b <= me_res;
                    mp_start <= '1';
                    state <= WAIT_LAMBDA;

                when WAIT_LAMBDA =>
                    mp_start <= '0';
                    if mp_done = '1' then
                        r_lambda <= mp_res;
                        state <= START_X3_SQ;
                    end if;

                when START_X3_SQ =>
                    mp_a <= r_lambda;
                    mp_b <= r_lambda;
                    mp_start <= '1';
                    state <= WAIT_X3_SQ;

                when WAIT_X3_SQ =>
                    mp_start <= '0';
                    if mp_done = '1' then
                        r_x3 <= mod_sub(unsigned(mp_res), unsigned(p1_x), unsigned(modulus));
                        state <= CALC_X3;
                    end if;

                when CALC_X3 =>
                    r_x3 <= mod_sub(unsigned(r_x3), unsigned(p2_x), unsigned(modulus));
                    state <= START_Y3;

                when START_Y3 =>
                    mp_a <= r_lambda;
                    mp_b <= mod_sub(unsigned(p1_x), unsigned(r_x3), unsigned(modulus));
                    mp_start <= '1';
                    state <= WAIT_Y3;

                when WAIT_Y3 =>
                    mp_start <= '0';
                    if mp_done = '1' then
                        res_x <= r_x3;
                        res_y <= mod_sub(unsigned(mp_res), unsigned(p1_y), unsigned(modulus));
                        state <= FINISH;
                    end if;

                when FINISH =>
                    done <= '1';
                    state <= IDLE;

            end case;
        end if;
    end process;

end Behavioral;
