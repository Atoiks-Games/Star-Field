/**
 * Copyright (C) 2018  Atoiks Games <atoiks-games@outlook.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.atoiks.games.starfield.server;

import java.io.IOException;

import java.net.Socket;
import java.net.InetAddress;
import java.net.ServerSocket;

import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;

import java.util.concurrent.atomic.AtomicBoolean;

public class Server implements AutoCloseable {

    public static final int NO_MAX_CLIENTS = -1;

    private final ServerSocket socket;

    private AtomicBoolean running = new AtomicBoolean(false);
    private ExecutorService socHandler = Executors.newCachedThreadPool();

    public Server(final int port) throws IOException {
        socket = new ServerSocket(port);
    }

    public void start() {
        start(NO_MAX_CLIENTS);
    }

    public void start(final int maxClients) {
        if (running.compareAndSet(false, true)) {
            socHandler.execute(() -> {
                int clients = 0;
                while (running.get()) {
                    try {
                        System.out.println("Waiting new socket connection");
                        final Socket soc = socket.accept();
                        if (clients < maxClients || maxClients < 0) {
                            System.out.println("Handling new socket connection");
                            final Handler handler = new Handler(soc, running);
                            socHandler.execute(handler);
                            ++clients;
                        } else {
                            System.out.println("Rejecting connection, client capacity reached");
                            soc.close();
                        }
                    } catch (IOException ex) {
                        System.out.println("Lost one...");
                    }
                }
            });
        }
    }

    public boolean isRunning() {
        return running.get();
    }

    public void stop() {
        running.set(false);
    }

    @Override
    public void close() throws IOException {
        running.set(false);
        socHandler.shutdown();
        socket.close();
    }
}