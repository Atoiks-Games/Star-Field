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

import java.net.Socket;
import java.net.SocketTimeoutException;

import java.io.IOException;
import java.io.BufferedWriter;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;

import java.util.ArrayList;

import java.util.function.BiConsumer;

import java.util.concurrent.atomic.AtomicBoolean;

public class Handler implements Runnable, BiConsumer<CBListWrapper.EventType, Ship> {

    public static final CBListWrapper<Ship> list = CBListWrapper.newList();

    private final Socket socket;
    private final BufferedWriter writer;
    private final BufferedReader reader;
    private final AtomicBoolean running;

    private final Ship ship;

    public Handler(final Socket socket, final AtomicBoolean running) throws IOException {
        this.socket = socket;
        this.running = running;

        // DO NOT PUT 0 OR 1 HERE: 0 DOES INFINITE WAITING, 1 CLOGS THE CLIENT SIDE CAUSING LAG
        this.socket.setSoTimeout(50);
        this.writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));
        this.reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));

        this.ship = new Ship(45, 10, list.stream().mapToInt(e -> e.getTeam() ? 1 : -1).sum() <= 0);
        list.add(ship);
        list.addCallback(this);
    }

    @Override
    public void accept(final CBListWrapper.EventType e, final Ship s) {
        try {
            switch (e) {
                case REMOVE:
                    writer.write(makeCmd('r', list.list.indexOf(s) + 1));
                    writer.newLine();
                    writer.flush();
                    break;
                case CLEAR:
                    writer.write(makeCmd('r', 0));
                    writer.newLine();
                    writer.flush();
                    break;
            }
        } catch (IOException ex) {
            System.out.println(ex);
        }
    }

    private String makeCmd(final char type, final int id) {
        return makeCmd(type, id, 0, 0, 0, "");
    }

    private String makeCmd(final char type, final int id, final String msg) {
        return makeCmd(type, id, 0, 0, 0, msg);
    }

    private String makeCmd(final char type, final int id, final double a) {
        return makeCmd(type, id, a, 0, 0, "");
    }

    private String makeCmd(final char type, final int id, final double a, final double b) {
        return makeCmd(type, id, a, b, 0, "");
    }

    private String makeCmd(final char type, final int id, final double a, final double b, final double c) {
        return makeCmd(type, id, a, b, c, "");
    }

    private String makeCmd(final char type, final int id, final double a, final double b, final double c, final String msg) {
        return "" + type + ',' + id + ',' + a + ',' + b + ',' + c + ',' + msg;
    }

    @Override
    public void run() {
        try {
            while (running.get()) {
                try {
                    final String s = reader.readLine();
                    if (s == null) break;
                    if (!s.isEmpty()) {
                        System.out.println(s);
                        final String[] k = s.substring(1).split(",");
                        switch (s.charAt(0)) {
                            case '@':   // {x}, {y}
                                ship.lookAndMoveTo(Double.parseDouble(k[0]), Double.parseDouble(k[1]));
                                break;
                            case 'f': { // {curve type}, {other ship's id}
                                final int ct = Integer.parseInt(k[0]);
                                final int id = Integer.parseInt(k[1]);
                                if (id != 0) {
                                    final Ship other = list.get(id - 1);
                                    final double dsp = ship.distanceBetween(other);
                                    other.hp -= ct == 0 ? Ship.curve1(dsp)
                                              : Ship.curve2(dsp);
                                }
                                break;
                            }
                        }
                    }
                } catch (SocketTimeoutException ex) {
                    // Ignore it
                }

                writer.write(makeCmd('h', 0, ship.hp));
                writer.newLine();

                for (int i = 0; i < list.size(); ++i) {
                    final Ship e = list.get(i);

                    if (e.hp <= 0) {
                        final boolean k = e == ship;
                        writer.write(makeCmd('!', k ? 0 : i + 1, k ? "You died!" : e.getTeam() == ship.getTeam() ? "Teammate down" : "Enemy player down"));
                        writer.newLine();
                        if (k) {
                            // Current player is dead, no need to send remaining player coordinates
                            break;
                        } else {
                            // Some player is dead, no need to send his/her coordinates
                            continue;
                        }
                    }

                    writer.write(makeCmd('@', e == ship ? 0 : i + 1, e.x, e.y, e.angle, e.getTeam() ? "Alpha" : "Beta"));
                    writer.newLine();
                }

                writer.flush();

                if (ship.hp <= 0) break;
            }
        } catch (IOException ex) {
            System.out.println(ex);
        }

        try {
            if (!socket.isClosed()) {
                this.socket.close();
            }
        } catch (IOException ex) {
            //
        }

        list.removeCallback(this);
        list.remove(ship);
    }
}