# Operativsystem 2022: Datorövning 2

Den grundläggande koden och testerna finns i repositoryn från början. Du får skapa egna filer, men huvudfilen (där `main`-funktionen finns) ska heta `sortwords.c`. Du får även skapa egna branches, men din lösning ska lämnas in på `main`-branchen.

## Automatiska tester

Uppgiften kommer till viss del att bedömas automatiskt beroende på om de program du gjort uppfyller vissa test. 

Första gången ni klonar er repo (eller startar den i Codespaces) så kommer inte de automatiska testerna (som är en git-submodul i katalogen test) att ha klonats. För att göra det här skriv följande kommandon i terminalen:
```
~ git submodule update --init --recursive
~ git submodule update --remote
```
Ifall testerna har uppdaterats (t.ex. om det varit någon bugg i något av testerna) kör följande kommando för att uppdatera till senaste version: 
```
~ git submodule update --remote
```
Det lönar sig att köra det här kommandot före du skickar in uppgiften för att verifiera att du har senaste test-versionen.

## Inlämning
Den version du har på `main`-branchen då tiden gått ut är den som bedöms. Ändringar som görs senare beaktas nödvändigtvis inte.

Före inlämning se till att du har en fil `student.txt` som innehåller en rad enligt följande mönster:

```git_användar_namn ditt hela namn```

Du får inte använda extern funktionalitet (förutom standard C-bibliotek) om det inte specifikt nämns i uppgiftstexten.

**Att göra egna modifikationer i filerna i test-katalogen (eller .gitmodules-filen eller ändra på testerna i Makefile) räknas som fusk!** 

## Allmänt in bedömningen
- Om ditt program inte kompilerar får du noll poäng för den uppgiften. 
- Den automatiska bedömningen som görs är nödvändigtvis inte slutgiltig. 
- Automatisk plagiatgranskning kan köras på koden.

## Beskrivning

Uppgiften är att skriva ett C-program som sorterar orden i en text given i ASCII-format utan att ta i beaktande stora eller små bokstäver. Sedan ska resultatet skrivas ut till en ny fil `output.txt` så att varje ord finns på en ny rad. Dessutom ska programmet skriva ut texten
`Read %zu rows and %zu words` till konsolen. Dupletter av ord ska även skrivas ut så många gånger de förekommer i texten. 

Modifiera filen `sortwords.c` så att programmet läser in texten från standardinput (terminalen). Om destinationsfilen `output.txt` existerar ska programmet returnera felkoden `1`, skriva ut ett meddelande som informerar användaren om detta och avbryta. 

Nu följer en stegvis förklaring hur detta kan göras, men observera att man inte behöver använda sig av exempelkoden i sin lösning.

### Läs in data 

För att lösa uppgiften, kan man först läsa in en rad i taget med hjälp av funktionen `getline`. Kolla manualen (`man getline`) för mer info. 

```
#include <stdio.h>

int main() 
{
    char *linep;
    size_t line_sz;
    ssize_t ret;
    linep = NULL;

    while ((ret = getline(&linep, &line_sz, stdin)) >= 0) 
    {
        free(linep);
        linep = NULL;
    }
    
    return 0;
}
``` 
Några saker att fundera på:
- Varför vill man köra `free()`?
- Varför skulle man sätta `linep` till `NULL` vid varje iteration?
- Varifrån kommer `stdin`?
- Vad är skillnaden på `size_t` och `ssize_t`?
- Vad är variabelnamnssuffixet `_sz` för något


För att sedan ge in textinnehåll till programmet kan man antingen kopiera och klistra in till terminalen, alternativt använda `pipe`-operatorn. T.ex.
```
./sortwords < inputfil.txt
```
kör programmet och läser in innehållet från `inputfil.txt` till programmet. 


### Konvertera texten till små bokstäver

Man kan konvertera alla bokstäver till små bokstäver med funktionen `tolower`. Läs manualen för funktionen för att förstå hur den används.

Alla bokstäver i `linep`-buffern konverteras till små bokstäver t.ex. med följande kodsnutt:
```
for (i = 0; i < line_sz; i++)
    linep[i] = tolower(linep[i]);
```

### Spara pekare till rader i en räcka

Spara pekare till alla rader i en räcka. Detta steg är på ett sätt onödigt, men gör det lättare att dela upp beskrivningen i flera mindre steg.

Här måste man allokera minne själv, vilket görs med `realloc()`. Minnesallokeringen försvåras av att vi inte på förhand vet hur mycket minne vi kommer att behöva. Vi kommer att behöva en array med en storlek proportionell till antalet rader i inputfilen. Om raden `lines[lines_len++]= linep;` ser besvärlig ut testa att flytta ut postinkrement-operatorn.

```
#include <stdio.h>
#include <stdlib.h>

int main()
{
    /* Something is missing here ... */
    char **lines;
    size_t lines_sz, lines_len;

    lines_sz = 11;
    lines_len = 0;
    lines = NULL;
    
    lines = realloc(lines, lines_sz * sizeof(char*));
    
    if (lines == NULL) 
    {
        perror("realloc()");
        return -1;
    }
    
    linep = NULL;

    while ((ret = getline(&linep, &line_sz, stdin)) >= 0) 
    {
        lines[lines_len++] = linep;
        
        while (lines_len >= lines_sz) 
        {
            lines_sz += 11;
            lines = realloc(lines, lines_sz * sizeof(char *));
        }

        linep = NULL;
    }

    for (i = 0; i < lines_len; i++)
        free(lines[i]);

    return 0;
}
```

### Dela upp texten i ord

För att kunna sortera orden, så måste vi nu dela upp raderna som lästs in i ord. Vi antar att ord inte kan vara delade över flera rader. Märk att inputen innehåller olika typer av extra tecken, t.ex. `.`, `,`, `;`, `-`, `?`, och `!` som vi måste ta bort. 

Tokeniseringen görs med hjälp av `strsep()`-funktionen (läs manualen). Observera att det är vissa tecken vi vill ignorera, därav den långa listan i andra argumentet. 

Eftersom vi kommer att behöva allokera minne också här, kommer vi delvis att använda samma programmeringsmönster som vi använde tidigare. Hur kan vi garantera att alla ord är c-strängar, dvs hur garanterar vi att de är `NULL`-terminerade (`\0`)?

```
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main()
{
    char *linep, *wordp, **words;
    size_t line_sz, words_sz, words_len;
    ssize_t ret;

    words_sz = 10;
    words_len = 0;
    words = NULL;
    
    words = realloc(words, words_sz * sizeof(char*));
    
    if (words == NULL) 
    {
        perror("realloc()");
        return -1;
    }

    linep = NULL;

    while ((ret = getline(&linep, &line_sz, stdin)) >= 0) 
    {
        while ((wordp = strsep(&linep, "1234567890()\"\' &$,.!?:[];\n\r\t")) != NULL) 
        {
            if (wordp == NULL)
                continue;

            if (wordp[0] == '\0')
                continue;
                
            words[words_len++] = wordp;
            
            while (words_len >= words_sz) 
            {
                words_sz += 10;
                words = realloc(words, words_sz * sizeof(char*));
            }
        }
        
        free(linep);
        linep = NULL;
    }
    
    return 0;
}
```

### Sortera orden

Order sorteras med `qsort()`-funktionen. Funktionen tar en funktionspekare (pekare till en funktion) som argument, vilket gör att man kan specificera sin egen jämförelsefunktion (`cmpstringp` i exemplet nedan).
```
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int cmpstringp(const void *p1, const void *p2)
{
/* The actual arguments to this function are 'pointers to pointers to char', but strcmp(3) arguments are 'pointers to char', hence the following cast plus dereference */
    return strcmp(* (char * const *) p1, * (char * const *) p2);
}

int main()
{
    char *linep, *wordp, **words;
    
    size_t line_sz, words_sz, words_len;
    ssize_t ret;
    
    words_sz = 10;
    words_len = 0;
    
    words = NULL;
    words = realloc(words, words_sz * sizeof(char*));
    
    if (words == NULL) 
    {
        perror("realloc()");
        return -1;
    }
    
    qsort(words, words_len, sizeof(char*), cmpstringp);
    
    return 0;
}
```

### Utskrift till fil

Skriv ut de sorterade orden till en fil, t.ex. genom att använda följande kod:

```
static int write_words(const char **words, size_t words_len, const char *filename)
{
    int ret;
    FILE *outfile;
    int i;
    outfile = fopen(filename, "wx");
    
    if (outfile == NULL) 
    {
        ret = -1;
        goto exit1;
    }
    
    for (i = 0; i < words_len, i++) 
    {
        if (fprintf(outfile, "%s ", words[i]) < 0) 
        {
            ret = -1;
            goto exit2;
        }
    }
    
    ret = 0;

exit2:
    fclose(outfile);

exit1:
    return ret;
}
```

Obs! Kom ihåg att frigöra allokerat minne!

## Exempel

För att ge in textinnehåll till programmet kan man antingen kopiera och klistra in till terminalen, alternativt använda pipe-operatorn. T.ex.
```
./sortwords < inputfil.txt
```
kör programmet och läser in innehållet från `inputfil.txt` till programmet på samma sätt som att man skulle skrivit texten för hand.

Programmet kompileras med `make sortwords`. 

## Bedömning: 
- 8 poäng om ditt program klarar av att sortera små texter (några rader) och i allmänhet fungerar enligt specifikationen ovan. T.ex. filen `test/100.txt`.
- Ytterligare 2 poäng om ditt program klarar av att läsa in en fil vars filnamn specificeras som argument, alltså `./sortwords test/100.txt`.
- Ytterligare 10 poäng om ditt program även klarar av att sortera "godtyckligt" stora filer. T.ex. filen `test/dumas.txt`.

## Testning
Du kan testa att ditt program fungerar med `make test`. Det finns en uppsättning test-filer med olika storlekar i test-katalogen (`test/*.txt`) som du alltså kan köra med `./sortwords < test/1000.txt`. 
