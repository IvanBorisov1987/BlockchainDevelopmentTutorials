/*запуск geth с параметрами /Users/ivanborisov/Desktop/geth --dev --rpc --rpcaddr "0.0.0.0" --rpcapi "admin,debug,miner,shh,txpool,personal,eth,net,web3" console
instance: Geth/v1.7.1-stable-05101641/darwin-amd64/go1.9
coinbase: 0x5098b211859c944e42baa3c6084ffbe3758f1cc2
at block: 0 (Thu, 01 Jan 1970 03:00:00 MSK)
 datadir: /var/folders/jj/h0j9kfbj2lx70kjt5yy_fl8m0000gn/T/ethereum_dev_mode
 modules: admin:1.0 debug:1.0 eth:1.0 miner:1.0 net:1.0 personal:1.0 rpc:1.0 shh:1.0 txpool:1.0 web3:1.0

> personal.newAccount("0000") - создание нового аккаунта
"0xb0adf1b153702c73a923e8528de214c9795c1d15"
> eth.accounts - показать все аккаунты на компьютере
["0x5098b211859c944e42baa3c6084ffbe3758f1cc2", "0xb0adf1b153702c73a923e8528de214c9795c1d15"]
> eth.coinbase   - показать основной кошелек
"0x5098b211859c944e42baa3c6084ffbe3758f1cc2"
> eth.getBalance(eth.coinbase) - показать баланс основного кошелька
0
> miner.start()    запуск майнинга
miner.stop()  остановка майнера
*/
pragma solidity ^0.4.16;   ///текущая версия языка

contract owned {     
    address public owner;

    function owned() public {   ///функция владения токеном
        owner = msg.sender;  ///владелец = отправитель сообщения
    }

    modifier onlyOwner {     ///модифицированная функция только для владельца токена равно отправитель сообщения == владелец токена
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;   /// функция передачи владения - создание объекта - новое владение
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; } ///требования для получения одобрения
///интерфейс получателя Токена
contract TokenERC20 {
    // Публичные переменные токена
    string public name = Pastila_Coin; ///имя токена
    string public symbol = PSTL; /// символ токена
    uint8 public decimals = 18; /// количество нулей - тип переменной из C# типа int
    // 18 нулей это настоятельно рекомендуемый настройка по умолчанию, не меняй его
    uint256 public totalSupply;  ///количество выпускаемых монет

    // Тут создается массив со всеми балансами
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // Тут создается публичное событие в блокчейне которое быдет уведомлять клиентов о передаче токена
    event Transfer(address indexed from, address indexed to, uint256 value); /// событие - передача 

    // Это уведомление о количестве сожженных токенов
    event Burn(address indexed from, uint256 value); ///событие сжигание токена
    /**
     * 1)Конструктив функций
     *
     * Инициализация контракта с начальным количеством токенов, созданных в контракте
     */
    function TokenERC20(
        uint256 initialSupply,   /// начальное количество
        string tokenName,  /// имя токена
        string tokenSymbol /// символ токена
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Обновление общего количества в десятичное число
        balanceOf[msg.sender] = totalSupply;                // Получение создателем всех начальных токенов
        name = tokenName;                                   // Присвоение имени для отображения
        symbol = tokenSymbol;                               // Присвоение символа для отображения
    }

    /**
     * 2)Внутреннее перемещение, только данный контракт может быть вызван
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Запретить передачу на 0x0 адреса. использовать burn()
        require(_to != 0x0);   ///требование
        // Проверка достаточно ли средств у отправителя
        require(balanceOf[_from] >= _value);
        // Проверка переизбытка
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // сохранение этого для доказательства в будущем
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Вычитание у оправителя и присвоение нового значения (-= a = a - b)
        balanceOf[_from] -= _value;  ///баланс отправителя - отправление
        // Добавление к получателю 
        balanceOf[_to] += _value; /// баланс получателя + отправление
        Transfer(_from, _to, _value);
        // Доказательства используются для использования статистического анализа для поиска ошибок в коде. Они никогда не ошибаются
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); /// доказательство баланс отправителя + баланс получателя = прошлый баланс
    }

    /**
     * Перемещение токенов
     *
     * Отправьте `_value` tokens to `_to` из вашего аккаунта
     *
     * @param _to //Адрес получателя
     * @param _value //сумма для отправления
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * 3) перемещение токена на другие адреса
     *
     * Отправьте `_value` токены `_to` от имени of `_from`
     *
     * @param _from ///адрес отправителя
     * @param _to ///адрес получателя
     * @param _value ///количество отправления
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {   ///функция отправления на другие
        require(_value <= allowance[_from][msg.sender]);     // Проверка учета
        allowance[_from][msg.sender] -= _value; 
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * 4) Установление учета для других адресов
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public ///одобрение
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Установление учета для другого адреса и уведомление об этом
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) ///одобри и сообщи
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * 5) Уничтожение токенов
     *
     * Удаление `_value` токенов из системы необратимо!!!!!
     *
     * @param _value ///количество для сжигания
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Проверка достаточности у отправителя
        balanceOf[msg.sender] -= _value;            // Вычитание из баланса отправителя
        totalSupply -= _value;                      // Обновление общего количества
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Удаление токенов на чужих кошельках
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Проверка достаточности баланса
        require(_value <= allowance[_from][msg.sender]);    // Проверка учтенности
        balanceOf[_from] -= _value;                         // удаление из целевого баланса
        allowance[_from][msg.sender] -= _value;             // Удаление из учета отправителей
        totalSupply -= _value;                              // Обновление общего баланса
        Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*Предварительный токен начинается тут    */
/******************************************/

contract MyAdvancedToken is owned, TokenERC20 {  /// контракт  MyAdvancedToken в собственности, наследование это объект класса TokenERC20

    uint256 public sellPrice; ///переменная цены продажи
    uint256 public buyPrice; /// переменная цены покупки

    mapping (address => bool) public frozenAccount;

    /* тут создается событие на блокчейне, которое будет уведомлять клиентов */
    event FrozenFunds(address target, bool frozen);

    /* инициализирует контракт с начальными токенами для передачи на контракт создателя */
    function MyAdvancedToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* Внутренне перемещение, только данный контракт может быть вызван */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Запрет to 0x0 address. использование burn() в противном случае
        require (balanceOf[_from] > _value);                // Проверка достаточно средст отправителя
        require (balanceOf[_to] + _value > balanceOf[_to]); // Проверка переполнения
        require(!frozenAccount[_from]);                     // проверка на заблокированность отправителя
        require(!frozenAccount[_to]);                       // проверка на заблокированность получетеля
        balanceOf[_from] -= _value;                         // удаление у отправителя
        balanceOf[_to] += _value;                           // тоже самое у получателя
        Transfer(_from, _to, _value);
    }
    /* 6) функция выпуск дополнительных монет - майнинг*/
    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Адрес для получения токенов
    /// @param mintedAmount количество токенов которое получится
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    /* 7) функция заморозки аккаунта */
    /// @notice `freeze? Prevent | Allow` `target` от отправки и получения токенов
    /// @param target Адрес заморозки
    /// @param freeze либо заморозить этот либо нет
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    /* 8) функция установки цены покупки и продажы токена  */
    /// @notice разрешение пользователям покупать токены `newBuyPrice` за эфир и продавать токены `newSellPrice` получая эфир
    /// @param newSellPrice Цена по которой пользователи могут продать по контракту и получить эфир
    /// @param newBuyPrice Цена по которой пользователи могут купить по контракту за эфир
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice покупка токенов из контракта, используя эфир
    function buy() payable public {
        uint amount = msg.value / buyPrice;               // расчитывает сумму
        _transfer(this, msg.sender, amount);              // делает переводы
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // проверка достаточности эфира на балансе для покупки
        _transfer(msg.sender, this, amount);              // совершает перевод
        msg.sender.transfer(amount * sellPrice);          // Отправка эфира продавцу. Важно сделать это в конце чтобы избежатьатак перебора(рекурсивных атак)
    }

    function myFunction(string name) private returns (bool) { /// запрет на просмотр строк кода
        return true;
    }
}