// Composition root — the ONLY place that knows how the concrete pieces
// fit together. Every dependency can be overridden by passing it in
// `overrides`, which is how tests inject fakes.
//
// Not a singleton: call createContainer() as many times as you need
// (e.g. one per test), each returns a fully isolated LMS.

import { InMemoryRepository } from "./repositories/InMemoryRepository.js";
import { IdGenerator } from "./utils/ids.js";
import { Logger } from "./utils/logger.js";
import { MemberFactory } from "./factories/memberFactory.js";
import { NotificationHub } from "./services/notificationHub.js";
import { Catalog } from "./services/catalog.js";
import { LoanService } from "./services/loanService.js";
import { StandardFineStrategy } from "./strategies/fineStrategies.js";
import { TitleSearchStrategy } from "./strategies/searchStrategies.js";

export function createContainer(overrides = {}) {
  const logger      = overrides.logger      ?? new Logger();
  const bookRepo    = overrides.bookRepo    ?? new InMemoryRepository();
  const memberRepo  = overrides.memberRepo  ?? new InMemoryRepository();
  const loanRepo    = overrides.loanRepo    ?? new InMemoryRepository();

  const memberIds   = overrides.memberIds   ?? new IdGenerator("M");
  const loanIds     = overrides.loanIds     ?? new IdGenerator("L");

  const hub           = overrides.hub           ?? new NotificationHub();
  const defaultSearch = overrides.defaultSearch ?? new TitleSearchStrategy();

  // Fine strategy needs a way to resolve a member from a loan; we build a
  // small closure around memberRepo so the strategy stays repo-agnostic.
  const fineStrategy = overrides.fineStrategy
    ?? new StandardFineStrategy((memberId) => memberRepo.findById(memberId));

  const memberFactory = overrides.memberFactory ?? new MemberFactory(memberIds);
  const catalog       = overrides.catalog       ?? new Catalog({ bookRepo, defaultSearch });
  const loans         = overrides.loans         ?? new LoanService({
    loanRepo, bookRepo, memberRepo, loanIds, fineStrategy, hub, logger,
  });

  return {
    logger, bookRepo, memberRepo, loanRepo,
    memberIds, loanIds,
    hub, defaultSearch, fineStrategy,
    memberFactory, catalog, loans,
  };
}
