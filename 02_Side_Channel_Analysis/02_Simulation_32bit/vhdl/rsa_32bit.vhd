library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rsa_32bit is
    Port ( clk      : in  STD_LOGIC;
           reset    : in  STD_LOGIC;
           start    : in  STD_LOGIC;
           msg_in   : in  STD_LOGIC_VECTOR (31 downto 0);
           key      : in  STD_LOGIC_VECTOR (31 downto 0);
           modulus  : in  STD_LOGIC_VECTOR (31 downto 0);
           data_out : out STD_LOGIC_VECTOR (31 downto 0);
           ready    : out STD_LOGIC);
end rsa_32bit;

architecture Structural of rsa_32bit is

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

    signal start_val : std_logic_vector(31 downto 0) := x"00000001"; 

begin

    mod_exp_inst : mod_exp
        generic map (
            DATA_WIDTH => 32
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
