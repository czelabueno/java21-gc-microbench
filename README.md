# How-to: Micro-benchmark de rendimiento de los GCs en el JDK 21 para un microservicio [en español]

Bien! Si has llegado hasta aqui es porque te interesó y has leído el articulo del `micro-benchmark`. En caso has llegado aqui directamente, te recomiendo que antes de continuar [leas el articulo](https://czelabueno.github.io/java21-gc-microbench/) primero. Te tomará 10 minutos.

Ahora sí, seguimos.

## Pre-requisitos
- Instala `JDK 21` usando [SDKMAN](https://sdkman.io/)

    ```
    $ sdk install java 21-graalce
    # No olvides escribir 'Y' para terminar la instalacion.
    $ sdk default java 21-graalce
    ```
- Instala `hey`, esta será la herramienta para lanzar las pruebas de carga http. El script asume que usas un SO linux. En caso uses otro, solo reemplaza la linea del `wget` por el [link de descarga](https://github.com/rakyll/hey#installation) correcto.

    ```
    echo "Installing hey HTTP load testing tool..."
    # Ubicate en una carpeta donde tengas permisos de escritura
    mkdir -p /home/czelabueno/tools
    cd /home/czelabueno/tools
    wget -q https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
    mv hey_linux_amd64 hey
    chmod +x hey
    export PATH=`pwd`:$PATH
    ```

    Listo! Ahora prueba que estan bien instaladas:

    ```
    $ java -version
    ```
    Resultado esperado:
    ```
    OpenJDK Runtime Environment GraalVM CE 21+35.1 (build 21+35-jvmci-23.1-b15)
    OpenJDK 64-Bit Server VM GraalVM CE 21+35.1 (build 21+35-jvmci-23.1-b15, mixed mode, sharing)
    ```
    Probando `hey`...
    ```
    $ hey
    ```
    Esperamos que el comando te solicite ingresar los parametros de `hey`, eso signica que ya lo tienes agregado al `path` y lo puedes ejecutar:
    ```
    Usage: hey [options...] <url>

    Options:
    -n  Number of requests to run. Default is 200.
    -c  Number of workers to run concurrently. Total number of requests cannot
        be smaller than the concurrency level. Default is 50.
    -q  Rate limit, in queries per second (QPS) per worker. Default is no rate limit.
    -z  Duration of application to send requests. When duration is reached,
        application stops and exits. If duration is specified, n is ignored.
        Examples: -z 10s -z 3m.
    -o  Output type. If none provided, a summary is printed.
        "csv" is the only supported alternative. Dumps the response
        metrics in comma-separated values format.
    ....
    ```

Listo ahora si pasamos al código.

## Clona el repo y genera el `.jar`
```
$ git clone https://github.com/czelabueno/java21-gc-microbench.git
$ cd quarkus-aot-sample
$ ./build.sh
```
... el `jar` lo debes encontrar con el nombre de `target/quarkus-aot-sample-1.0.0-SNAPSHOT-runner.jar`

Si hemos llegado hasta aqui sin fallas es que ya tenemos nuestra aplicacion generada para correr las pruebas con diferentes Garbage Collectors (GC).


## Ejecucion de pruebas

**Sugerencia** 
Usa un terminal para levantar la aplicación y otro para correr los scrtips de pruebas de carga y/o estres.

### Parallel GC

Corremos la aplicacion utilizando el GC `ParallelGC` activando el debug.
Con el debug podremos ver más detalles de las pausas y los tiempos de ejecución que va midiendo el mismo GC.

Corremos la aplicacion...
```
java -verbose:gc -XX:+UseParallelGC -jar target/quarkus-aot-sample-1.0.0-SNAPSHOT-runner.jar &

```
Corremos el script de carga...
```
$ ./load-test-gc.sh Parallel
```
Esta carga generará aprox 1MM de solicitudes en 20 segundos utilizando 4 workers de `hey`

El resultado de la ejecucion debe lucir algo como esto:
```
Performance stats for JDK Parallel Garbage Collector

PID 90052: MAX RSS 93.0M
Throughput req/s: 54444.5795
Latency of 99% of Requests: 100 μs(microseconds)
Total responses: 1000000 [200 OK]

```
Listo! Ya podras ver los resultados del throughtput req/s, max memoria utilizada y latencia del 99% (las 3 metricas de rendimiento que queremos comparar).

Puedes sostener la carga ejecutando este mismo script una, dos y hasta tres veces si así lo prefieres. Solamente recuerda que debes ejecutar la misma carga para todos los GC para hacer una comparación justa.

Una vez terminadas las pruebas seran guardadas automaticamente en estos 2 archivos:
- `JDK_21_Parallel.txt` el ultimo `output` de la ejecucion de `hey`.
- `JDK_21_Parallel_metrics.txt` resumen y resultado final de las metricas.

Detenemos la aplicacion...

Si lo estas corriendo en background ejecuta el comando de abajo sino solo haz `ctl + c` para detener la aplicacion.
```
$ ps aux | grep quarkus-aot-sample-1.0.0-SNAPSHOT-runner
$ kill -9 <PID>
```

### G1 GC

Ahora repetiremos los mismos pasos pero ejecutaremos la aplicacion usando el `G1GC`. Recordemos que este es el GC por defecto por lo que no es necesario especificar el GC cuando lo corramos.


Corremos la aplicacion...
```
java -verbose:gc -jar target/quarkus-aot-sample-1.0.0-SNAPSHOT-runner.jar &

```
Corremos el script de carga...
```
$ ./load-test-gc.sh G1
```
Esta carga generara aprox 1MM de solicitudes en 20 segundos utilizando 4 workers de `hey`

Una vez terminadas las pruebas, los resultados también serán guardados automaticamente en estos 2 archivos:
- `JDK_21_G1.txt` el ultimo `output` de la ejecucion de `hey`.
- `JDK_21_G1_metrics.txt` resumen y resultado final de las metricas.

Detenemos la aplicación...

Si lo estas corriendo en background ejecuta el comando de abajo sino solo haz `ctl + c` para detener la aplicación.
```
$ ps aux | grep quarkus-aot-sample-1.0.0-SNAPSHOT-runner
$ kill -9 <PID>
```
### ZGC
Corremos la aplicación...
```
java -verbose:gc -XX:+UseZGC -jar target/quarkus-aot-sample-1.0.0-SNAPSHOT-runner.jar &

```
Corremos el script de carga las mismas veces que corriste para las anteriores...
```
$ ./load-test-gc.sh ZGC
```

Una vez terminadas las pruebas, los resultados tambien seran guardados automaticamente en estos 2 archivos:
- `JDK_21_ZGC.txt` el ultimo `output` de la ejecucion de `hey`.
- `JDK_21_ZGC_metrics.txt` resumen y resultado final de las metricas.

Detenemos la aplicacion...

Si lo estas corriendo en background ejecuta el comando de abajo sino solo haz `ctl + c` para detener la aplicacion.
```
$ ps aux | grep quarkus-aot-sample-1.0.0-SNAPSHOT-runner
$ kill -9 <PID>
```
### Generational ZGC

Corremos la aplicacion...
```
java -verbose:gc -XX:+UseZGC -XX:+ZGenerational -jar target/quarkus-aot-sample-1.0.0-SNAPSHOT-runner.jar &

```
Corremos el script de carga las mismas veces que corriste para las anteriores...
```
$ ./load-test-gc.sh GenerationalZGC
```

Una vez terminadas las pruebas, los resultados tambien seran guardados automaticamente en estos 2 archivos:
- `JDK_21_GenerationalZGC.txt` el ultimo `output` de la ejecucion de `hey`.
- `JDK_21_GenerationalZGC_metrics.txt` resumen y resultado final de las metricas.

Detenemos la aplicacion...

Si lo estas corriendo en background ejecuta el comando de abajo sino solo haz `ctl + c` para detener la aplicacion.
```
$ ps aux | grep quarkus-aot-sample-1.0.0-SNAPSHOT-runner
$ kill -9 <PID>
```

Listo! Hasta aquí ya hemos terminado de recolectar las 3 metricas (`max rss`, `throughput`, `latencia 99%`) de rendimiento para las 4 implementaciones de GC. 🙌

## Análisis de resultados 📊
En este [artículo](https://czelabueno.github.io/java21-gc-microbench/) hice un análisis detallado y comparativo de este micro-bench.

Como resumen podemos concluir que el `G1GC` puede ofrecer un mejor balance entre throughput y latencia para garantizar disponibilidad y consuma la menor cantidad de memoria posible para ser mas costo-eficiente durante el escalamiento horizontal de un microservicio.

Sin embargo, te recomiendo que utilices las metricas recolectadas para que evalues cada una de acuerdo a los objetivos de tu aplicacion. 

Contribuyamos con la reducción de CO2 y el consumo de energia eléctrica ♻️ consumiendo la menor cantidad posible memoria, cpu, storage, etc.


Happy coding!

[Carlos Zela](https://sessionize.com/czelabueno)


