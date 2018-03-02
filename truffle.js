module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 7545, // ganache port
      network_id: '*',
    },
    ganache: {
      host: "localhost",
      port: 7545,
      network_id: '*'
    }
  }
};
