module lexer.lexer;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.algorithm.searching : canFind;
import std.ascii : isAlpha, isDigit, isAlphaNum;
import std.uni : isWhite;


enum TokenType
{
    WRITE,
    WRITELN,
    WRITEF,
    IF,
    ELSE,
    IMPORT,
    VAR,
    LITERAL_STRING,
    LITERAL_NUMBER,
    VARIABLE,
    ASSIGNMENT,
    PLUS,
    MINUS,
    MULTIPLY,
    DIVIDE,
    GREATER,
    LESS,
    LESS_EQUAL,
    GREATER_EQUAL,
    NOT_EQUAL,
    EQUALS,
    LBRACE,
    RBRACE,
    LPAREN,
    RPAREN,
    COMMA,
    TILDE,
    SEMICOLON,
    EOF
}

class Token
{
    TokenType type;
    string value;
    size_t line;
    size_t column;

    this(TokenType type, string value, size_t line, size_t column)
    {
        this.type = type;
        this.value = value;
        this.line = line;
        this.column = column;
    }
}

class Lexer
{
private:
    string input;
    size_t pos;
    size_t line;
    size_t column;

    immutable string[] keywords = ["write", "writeln", "writef", "var", "if", "else"];
    
    bool isKeyword(string ident)
    {
        return keywords.canFind(ident);
    }

public:
    this(string input)
    {
        this.input = input;
        this.pos = 0;
        this.line = 1;
        this.column = 1;
    }

    Token[] lex()
    {
        Token[] tokens;

        while (pos < input.length)
        {
            char current = input[pos];

            if (isWhite(current))
            {
                skipWhitespace();
                continue;
            }

            if (current == '"')
            {
                tokens ~= readString();
                continue;
            }

            if (isDigit(current))
            {
                tokens ~= readNumber();
                continue;
            }

            if (isAlpha(current))
            {
                tokens ~= readIdentifier();
                continue;
            }

            Token opToken = readOperatorOrPunctuation();
            if (opToken !is null)
            {
                tokens ~= opToken;
                continue;
            }

            advance();
        }

        tokens ~= new Token(TokenType.EOF, "", line, column);
        return tokens;
    }

private:
    void advance(size_t count = 1)
    {
        foreach (_; 0..count)
        {
            if (pos >= input.length) return;
        
            if (input[pos] == '\n')
            {
                ++line;
                column = 1;
            }

            else
            {
                ++column;
            }
            ++pos;
        }
    }

    void skipWhitespace()
    {
        while (pos < input.length)
        {
            char current = input[pos];
        
            if (isWhite(current))
            {
                advance();
                continue;
            }
        
            // Обработка комментариев (пропускаем их)
            if (current == '#' || (current == '/' && pos + 1 < input.length && input[pos + 1] == '/')) 
            {
                while (pos < input.length && input[pos] != '\n')
                {
                    advance();
                }
                continue;
            }
        
            if (current == '/' && pos+1 < input.length && input[pos+1] == '*')
            {
                advance(2);
                while (pos+1 < input.length && !(input[pos] == '*' && input[pos+1] == '/'))
                {
                    advance();
                }
                if (pos+1 >= input.length)
                {
                    throw new Exception("Unterminated multiline comment");
                }
                advance(2);
                continue;
            }
        
            break;
        }
    }

    Token readString()
    {
        size_t startLine = line;
        size_t startColumn = column;
        size_t startPos = pos;

        advance(); // Skip opening quote

        while (pos < input.length && input[pos] != '"')
        {
            advance();
        }

        if (pos >= input.length)
        {
            throw new Exception("Unterminated string literal");
        }

        advance(); // Skip closing quote
        return new Token(TokenType.LITERAL_STRING, input[startPos..pos], startLine, startColumn);
    }

    Token readNumber()
    {
        size_t startLine = line;
        size_t startColumn = column;
        size_t startPos = pos;

        while (pos < input.length && isDigit(input[pos]))
        {
            advance();
        }

        return new Token(TokenType.LITERAL_NUMBER, input[startPos..pos], startLine, startColumn);
    }

    Token readIdentifier()
    {
        size_t startLine = line;
        size_t startColumn = column;
        size_t startPos = pos;

        while (pos < input.length && isAlphaNum(input[pos]))
        {
            advance();
        }

        string ident = input[startPos..pos];

        if (ident == "write") return new Token(TokenType.WRITE, ident, startLine, startColumn);
        if (ident == "writeln") return new Token(TokenType.WRITELN, ident, startLine, startColumn);
        if (ident == "writef") return new Token(TokenType.WRITEF, ident, startLine, startColumn);
        if (ident == "import") return new Token(TokenType.IMPORT, ident, startLine, startColumn);     
        if (ident == "var") return new Token(TokenType.VAR, ident, startLine, startColumn);      
        if (ident == "if") return new Token(TokenType.IF, ident, startLine, startColumn);  
        if (ident == "else") return new Token(TokenType.ELSE, ident, startLine, startColumn);                  

        return new Token(TokenType.VARIABLE, ident, startLine, startColumn);
    }

    Token readOperatorOrPunctuation()
    {
        size_t startLine = line;
        size_t startColumn = column;
        char current = input[pos];

        switch (current)
        {
            case '=':
                advance();
                if(pos < input.length && input[pos] == '=')
                {
                    advance();
                    return new Token(TokenType.EQUALS, "==", startLine, startColumn);
                }

                else
                {
                    return new Token(TokenType.ASSIGNMENT, "=", startLine, startColumn);
                }

            case '!':
                advance();
                if(pos < input.length && input[pos] == '=')
                {
                    advance();
                    return new Token(TokenType.EQUALS, "!=", startLine, startColumn);
                }

                else
                {
                    throw new Exception("Unexpected character '!'");
                }

            case '+':
                advance();
                return new Token(TokenType.PLUS, "+", startLine, startColumn);

            case '-':
                advance();
                return new Token(TokenType.MINUS, "-", startLine, startColumn);

            case '*':
                advance();
                return new Token(TokenType.MULTIPLY, "*", startLine, startColumn);

            case '/':
                advance();
                return new Token(TokenType.DIVIDE, "/", startLine, startColumn);

            case '(':
                advance();
                return new Token(TokenType.LPAREN, "(", startLine, startColumn);

            case ')':
                advance();
                return new Token(TokenType.RPAREN, ")", startLine, startColumn);

            case ',':
                advance();
                return new Token(TokenType.COMMA, ",", startLine, startColumn);

            case ';':
                advance();
                return new Token(TokenType.SEMICOLON, ";", startLine, startColumn);

            case '~':
                advance();
                return new Token(TokenType.TILDE, "~", startLine, startColumn);

            case '{':
                advance();
                return new Token(TokenType.LBRACE, "{", startLine, startColumn);

            case '}':
                advance();
                return new Token(TokenType.RBRACE, "}", startLine, startColumn);

            case '>':
                advance();
                if(pos < input.length && input[pos] == '=')
                {
                    advance();
                    return new Token(TokenType.GREATER_EQUAL, ">=", startLine, startColumn);
                }

                else
                {
                    return new Token(TokenType.GREATER, ">", startLine, startColumn);
                }

            case '<':
                advance();
                if(pos < input.length && input[pos] == '=')
                {   
                    advance();
                    return new Token(TokenType.LESS_EQUAL, "<=", startLine, startColumn);
                }

                else
                {
                    return new Token(TokenType.LESS, "<", startLine, startColumn);
                }

            default:
                return null;
        }

        new Token(TokenType.EOF, "", 0, 0);
    }
}