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

public class Ship {

    public static final int MIN_X = -800;
    public static final int MAX_X = 800;
    public static final int MIN_Y = -600;
    public static final int MAX_Y = 600;

    public double x, y, angle, hp;

    private double destX, destY;
    private double speed;
    private boolean isTeamA;

    public Ship(final double speed, final double hp, final boolean teamA) {
        this(Math.random() * (MAX_X - MIN_X) + MIN_X, Math.random() * (MAX_Y - MIN_Y) + MIN_Y, speed, hp, 0, teamA);
        this.lookAt(0, 0);
    }

    public Ship(final double x, final double y, final double speed, final double hp, final double angle, final boolean teamA) {
        this.x = this.destX = x;
        this.y = this.destY = y;
        this.speed = speed;
        this.angle = angle;
        this.hp = hp;
        this.isTeamA = teamA;
    }

    public boolean getTeam() {
        return isTeamA;
    }

    public void lookAndMoveTo(final double x, final double y) {
        this.lookAt(x, y);
        this.moveTo(x, y);
    }

    public final void lookAt(final double x, final double y) {
        this.angle = Math.atan2(this.y - y, this.x - x);
    }

    public void moveTo(final double x, final double y) {
        this.destX = x;
        this.destY = y;
    }

    public void update(final float dt) {
        if (!this.reachDest()) {
            final double dx = this.speed * Math.cos(this.angle) * dt;
            final double dy = this.speed * Math.sin(this.angle) * dt;

            // Stop player from overshooting destination
            this.x = (Math.abs(dx) > Math.abs(this.x - this.destX))
                   ? this.destX : this.x - dx;
            this.y = (Math.abs(dy) > Math.abs(this.y - this.destY))
                   ? this.destY : this.y - dy;

            // Restrict player within world boundaries
            this.x = Math.max(Math.min(this.x, MAX_X), MIN_X);
            this.y = Math.max(Math.min(this.y, MAX_Y), MIN_Y);
        }
    }

    public boolean reachDest() {
        return (this.x == this.destX && this.y == this.destY)
            || this.x < MIN_X || this.x > MAX_X
            || this.y < MIN_Y || this.y > MAX_Y;
    }

    public double distanceBetween(final Ship other) {
        if (this == other) return 0;
        return this.distanceBetween(other.x, other.y);
    }

    public double distanceBetween(final double x, final double y) {
        return Math.hypot(this.x - x, this.y - y);
    }

    public static double curve1(final double rx) {
        final double x = Math.ceil(rx / 2);
        return (208 * x + 70) / (x * x + 30);
    }

    public static double curve2(final double x) {
        final int k = (int) Math.ceil(x / 3);
        if (k == 0) return 0;
        return 1.5 * Math.max(0, 31 - Integer.numberOfLeadingZeros(k));
    }
}