// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/*  Representación del contrato i_router de Uniswap V2, que permite a este 
contrato llamar a sus funciones externas */
interface IUniswapV2i_router02 {
    // Devuelve la dirección del token WETH (Wrapped Ether), esencial para manejar swaps que involucran a ETH
    function WETH() external pure returns (address);
   

    /* Ejecuta un swap donde conoces la cantidad exacta de token de entrada (amountIn) y especificas la cantidad mínima a recibir (amountOutMin)*/
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /* Ejecuta un swap donde la entrada es Ether nativo (usando payable) y se especifica la cantidad mínima a recibir (amountOutMin) */
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}