import java.util.*;

/*
 * Необходимо написать собственную хеш-функцию
 1.на вход подается строка символов: сообщение
 2. на выходе получается строка символов: хеш
 1. каждый символ имеет свое числовое представление в таблице ASCII
 2. допустимые символы на входе и на выходе: 0..9, a..z, A..Z
 Notes:
 1. с цифрами можно проводить различные арифметические операции
 2. после арифметических операций получается какая-то строка, состоящая только из цифр 0..9
 3. далее эту строку необходимо перевести в смиволы: 0..9, a..z, A..Z - это и будет хеш
 4. цифры должны переводиться в символы однозначным соответствием, то есть, должна быть таблица соответствия какого-то
 символа конкретной цифре от 0..9
 */

public class HashFunction {
    private static final int POWER = 7;
    private static final int HASH_SIZE = 8;

    public static void main(String[] args) {
        char[] word = getWord();
        char lastLetter = word[word.length - 1];

        Map<Integer, Character> table = new HashMap<>();
        table.put(0, 'a');
        table.put(1, '3');
        table.put(2, 'F');
        table.put(3, '9');
        table.put(4, 'P');
        table.put(5, 'w');
        table.put(6, '7');
        table.put(7, 'b');
        table.put(8, 'k');
        table.put(9, 's');

        StringBuilder output = new StringBuilder();

        //арифметические операции - получаем строку из цифр
        for (int i = 0; i < word.length; i++) {
            String s = String.valueOf(formula(word[i], lastLetter));
            output.append(s.substring(2, s.length()));
        }

        //для каждой цифры получаем соответствующий символ
        char[] digits = output.toString().toCharArray();
        char[] line = new char[output.length()];

        for (int i = 0; i < line.length; i++) {
            line[i] = table.get(Character.getNumericValue(digits[i]));
        }

        //ограничиваем результат до HASH_SIZE символов
        char[] result = new char[HASH_SIZE];

        if (line.length < HASH_SIZE) {
            for (int i = 0; i < line.length; i++) {
                result[i] = line[i];
            }

            for (int i = line.length; i < HASH_SIZE; i++) {
                result[i] = line[i % line.length];
            }
        } else {
            int ratio = (line.length - HASH_SIZE) >> 1;

            for (int i = 0; i < HASH_SIZE; i++) {
                result[i] = line[i + ratio];
            }
        }

        System.out.println(result);
    }

    private static char[] getWord() {
        Scanner scanner = new Scanner(System.in);
        return scanner.nextLine().toLowerCase().toCharArray();
    }

    private static int formula(char a, char b) {
        return (ord(a) * ord(b)) << POWER;
    }

    private static int ord(char c) {
        return c;
    }

}