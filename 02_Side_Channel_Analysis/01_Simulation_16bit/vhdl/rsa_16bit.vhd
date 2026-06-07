library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rsa_16bit is
    Port ( clk      : in  STD_LOGIC;
           reset    : in  STD_LOGIC;
           start    : in  STD_LOGIC;
           msg_in   : in  STD_LOGIC_VECTOR (15 downto 0);
           key      : in  STD_LOGIC_VECTOR (15 downto 0);
           modulus  : in  STD_LOGIC_VECTOR (15 downto 0);
           data_out : out STD_LOGIC_VECTOR (15 downto 0);
           ready    : out STD_LOGIC);
end rsa_16bit;

architecture Structural of rsa_16bit is

    component mod_exp is
        Generic (
            DATA_WIDTH : integer := 32
        );
        Port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            start       : in  std_logic;
            start_value : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            base        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            exp         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            modulus     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            result      : out std_logic_vector(DATA_WIDTH-1 downto 0);
            done        : out std_logic
        );
    end component;

    signal start_val : std_logic_vector(15 downto 0) := x"0001"; -- Typically 1 for standard modular exponentiation

begin

    -- Instantiate the modular exponentiation module with DATA_WIDTH=16
    mod_exp_inst : mod_exp
        generic map (
            DATA_WIDTH => 16
        )
        port map (
            clk         => clk,
            rst         => reset,
            start       => start,
            start_value => start_val,
            base        => msg_in,
            exp         => key,
            modulus     => modulus,
            result      => data_out,
            done        => ready
        );

end Structural;
